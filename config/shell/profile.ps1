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

# --- PSReadLine：历史前缀搜索 + 菜单补全 + 基于历史的预测 ---
# PowerShell 7 内置模块；Set-PSReadLineOption 的预测选项需 >= 2.1，
# 2.2.6+ 默认开启。低版本用 try/catch 兜底，不影响其余初始化。
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine

    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete

    try {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle InlineView
    } catch {
        Write-Verbose "PSReadLine 预测不可用（版本偏低）: $($_.Exception.Message)"
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
