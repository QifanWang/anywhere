# anywhere / PowerShell 7 shell 交互配置
# 位置：$env:XDG_CONFIG_HOME\shell\profile.ps1（由 scripts/win11/bootstrap.ps1 链接）
# 加载：bootstrap 自动在 $PROFILE.CurrentUserAllHosts 注入 managed block（可用 -SkipProfile 跳过）
#   . "$env:XDG_CONFIG_HOME\shell\profile.ps1"
# 加载顺序：eza 别名 -> PSReadLine -> zoxide -> oh-my-posh
# 每项都做存在性检查，缺任一工具都不会让 shell 启动失败。
# 对应 Unix 的 env.sh（bash / zsh）。

if ($env:XDG_CONFIG_HOME) {
    $anywhereCfg = $env:XDG_CONFIG_HOME
} else {
    $anywhereCfg = Join-Path $HOME ".config"
}

# --- eza 别名（沿用 config/eza/aliases.ps1，避免两处维护） ---
$ezaAliases = Join-Path $anywhereCfg "eza\aliases.ps1"
if (Test-Path -LiteralPath $ezaAliases) {
    . $ezaAliases
}

# --- fzf 候选源：用 fd 列文件（对齐 Unix env.sh，供 yazi 的 z 等使用） ---
if (Get-Command fd -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --type d --hidden --follow --exclude .git'
}

# --- PSReadLine：历史前缀搜索 + 菜单补全 + 插件增强的智能预测 ---
# PowerShell 7 内置模块；CompletionPredictor（PSGallery）提供基于 AST 的补全预测，
# 与历史预测合并为 HistoryAndPlugin；ListView 为 fish 风格多选下拉。
# 插件缺失时自动退化为 History，PSFzf 缺失时保留内置 Ctrl+R，均不影响 shell 启动。
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine

    Set-PSReadLineKeyHandler -Chord UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Chord DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord Tab       -Function MenuComplete

    # CompletionPredictor 通过 PSSubsystem 注册插件，导入后 Plugin 预测源才生效
    if (Get-Module -ListAvailable CompletionPredictor -ErrorAction SilentlyContinue) {
        Import-Module CompletionPredictor -ErrorAction SilentlyContinue
    }

    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
    } catch {
        Write-Verbose "PSReadLine 预测配置不可用（版本偏低）: $($_.Exception.Message)"
    }

    # PSFzf 接管 Ctrl+R：fzf 模糊搜索历史（依赖 fzf 二进制在 PATH）
    # PSFzf 2.7.x 用 Set-PsFzfOption 绑定，处理函数为 Invoke-FzfPsReadlineHandlerHistory
    if ((Get-Module -ListAvailable PSFzf -ErrorAction SilentlyContinue) -and
        (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Import-Module PSFzf -ErrorAction SilentlyContinue
        if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
            try {
                Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r' -ErrorAction Stop
            } catch {
                Write-Verbose "PSFzf Ctrl+R 绑定失败: $($_.Exception.Message)"
            }
        }
    }
}

# --- zoxide：接管 cd，提供 z / zi 目录跳转 ---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# --- oh-my-posh：提示符（最后初始化，输出 prompt 脚本） ---
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompTheme = Join-Path $anywhereCfg "oh-my-posh\anywhere.omp.json"
    if (Test-Path -LiteralPath $ompTheme) {
        oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
    }
}

# --- yazi -> shell wrappers（对应 Unix env.sh 的 y / yg / gw）---
# 临时文件用 GUID 命名，避免多会话并发时互相覆盖
function Get-AnywhereConsoleWidth {
    try {
        $width = [Console]::WindowWidth
        if ($width -gt 0) { return $width }
    } catch { }
    try {
        $width = $Host.UI.RawUI.WindowSize.Width
        if ($width -gt 0) { return $width }
    } catch { }
    return 0
}

# 临时设置 GLOW_WIDTH（glow v3 非 TTY 默认 80），调用后恢复原值
function Invoke-AnywhereGlow {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GlowArgs)
    $saved = $env:GLOW_WIDTH
    $env:GLOW_WIDTH = [string](Get-AnywhereConsoleWidth)
    try {
        glow @GlowArgs
    } finally {
        if ($null -eq $saved) {
            Remove-Item Env:GLOW_WIDTH -ErrorAction SilentlyContinue
        } else {
            $env:GLOW_WIDTH = $saved
        }
    }
}

# y: 退出 yazi 后 cd 到浏览目录（按 Q 退出则不切换）
if (Get-Command yazi -ErrorAction SilentlyContinue) {
    function y {
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("yazi-cwd-{0}.tmp" -f [guid]::NewGuid().ToString('N'))
        try {
            yazi @args "--cwd-file=$tmp"
            $cwd = Get-Content -LiteralPath $tmp -Raw -ErrorAction SilentlyContinue
            if ($cwd) { $cwd = $cwd.Trim() }
            $here = (Get-Location).ProviderPath
            if ($cwd -and -not [string]::Equals($cwd, $here, [System.StringComparison]::OrdinalIgnoreCase)) {
                Set-Location -LiteralPath $cwd -ErrorAction SilentlyContinue
            }
        } finally {
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        }
        return
    }
}

# yg: 在 yazi 里选文件，退出后按终端宽度用 glow 精读
if ((Get-Command yazi -ErrorAction SilentlyContinue) -and (Get-Command glow -ErrorAction SilentlyContinue)) {
    function yg {
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("yazi-chooser-{0}.tmp" -f [guid]::NewGuid().ToString('N'))
        try {
            yazi @args "--chooser-file=$tmp"
            $file = if (Test-Path -LiteralPath $tmp) { Get-Content -LiteralPath $tmp -TotalCount 1 -ErrorAction SilentlyContinue }
            if ($file -and (Test-Path -LiteralPath $file -PathType Leaf)) {
                Invoke-AnywhereGlow $file
            }
        } finally {
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        }
        return
    }
}

# gw: 按当前终端宽度渲染 glow（绕开 v3 的 120 列上限）
if (Get-Command glow -ErrorAction SilentlyContinue) {
    function gw {
        Invoke-AnywhereGlow @args
    }
}
