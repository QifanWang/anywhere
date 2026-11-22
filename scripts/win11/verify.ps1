# 3.2 验证：在新开的 PowerShell 7 中运行，确认工具链已全部就绪并加载配置
# 只做非交互式检查；rmux / yazi / glow 的交互项见 docs/win11-toolchain.md

[CmdletBinding()]
param()

$script:results = @()

function Add-Result {
    param(
        [string]$Item,
        [bool]$Ok,
        [string]$Detail = ""
    )
    $script:results += [pscustomobject]@{ Item = $Item; Ok = $Ok; Detail = $Detail }
}

function Get-ToolVersion {
    param([string]$Name, [string[]]$Arguments)
    try {
        $output = & $Name @Arguments 2>&1 | Select-Object -First 1
        return ([string]$output).Trim()
    } catch {
        return ""
    }
}

Write-Host "==> Shell"
if ($PSVersionTable.PSVersion.Major -eq 7) {
    Add-Result "PowerShell 7" $true ([string]$PSVersionTable.PSVersion)
} else {
    Add-Result "PowerShell 7" $false ([string]$PSVersionTable.PSVersion)
}

Write-Host "`n==> Commands"
foreach ($name in @("winget", "wt", "rmux", "eza", "glow", "yazi", "hx", "fd", "fzf", "lazygit", "zoxide", "oh-my-posh")) {
    if (Get-Command $name -ErrorAction SilentlyContinue) {
        Add-Result $name $true
    } else {
        Add-Result $name $false "不在 PATH（可能需要重开终端）"
    }
}

Write-Host "`n==> Versions"
$tools = @(
    @{ Name = "rmux";       Args = @("-V") },
    @{ Name = "eza";        Args = @("--version") },
    @{ Name = "glow";       Args = @("--version") },
    @{ Name = "yazi";       Args = @("--version") },
    @{ Name = "hx";         Args = @("--version") },
    @{ Name = "fd";         Args = @("--version") },
    @{ Name = "fzf";        Args = @("--version") },
    @{ Name = "lazygit";    Args = @("--version") },
    @{ Name = "zoxide";     Args = @("--version") },
    @{ Name = "oh-my-posh"; Args = @("--version") }
)
foreach ($tool in $tools) {
    $version = Get-ToolVersion -Name $tool.Name -Arguments $tool.Args
    if ($version) {
        Add-Result "$($tool.Name) version" $true $version
    } else {
        Add-Result "$($tool.Name) version" $false "无法读取版本输出"
    }
}

Write-Host "`n==> rmux keybindings"
$keys = & rmux list-keys -N 2>&1
if ($LASTEXITCODE -eq 0 -and $keys) {
    Add-Result "rmux list-keys -N" $true "前缀键与自定义键位已加载"
} else {
    Add-Result "rmux list-keys -N" $false "读取失败（配置可能未链接）"
}

Write-Host "`n==> Shell integration"
# $PROFILE 的 4 个变体都查一遍，用户写进哪个都算（文档示例用的是 $PROFILE.CurrentUserCurrentHost）
$profileText = ""
foreach ($path in @($PROFILE, $PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost,
                    $PROFILE.AllUsersAllHosts, $PROFILE.AllUsersCurrentHost)) {
    if ($path -and (Test-Path -LiteralPath $path)) {
        $profileText += Get-Content -LiteralPath $path -Raw
    }
}
if ($profileText -match 'shell[\\/]profile\.ps1') {
    Add-Result '$PROFILE -> profile.ps1' $true "已加载 shell 交互配置"
} else {
    Add-Result '$PROFILE -> profile.ps1' $false "未在任何 `$PROFILE 找到 dot-source 行（应含 shell\profile.ps1）"
}

$psrl = Get-Module PSReadLine
if ($psrl) {
    Add-Result "PSReadLine" $true ([string]$psrl.Version)
} else {
    Add-Result "PSReadLine" $false "未加载（需 PowerShell 7）"
}

# PSReadLine 智能预测：CompletionPredictor 插件 + HistoryAndPlugin + ListView + PSFzf 接管 Ctrl+R
$predictor = Get-Module CompletionPredictor -ErrorAction SilentlyContinue
if ($predictor) {
    Add-Result "CompletionPredictor" $true ([string]$predictor.Version)
} else {
    Add-Result "CompletionPredictor" $false "未加载；检查 PSGallery 安装并重开终端"
}
$psfzf = Get-Module PSFzf -ErrorAction SilentlyContinue
if ($psfzf) {
    Add-Result "PSFzf" $true ([string]$psfzf.Version)
} else {
    Add-Result "PSFzf" $false "未加载；检查 PSGallery 安装并重开终端"
}
if ($psrl) {
    # PSReadLine 在输出被重定向（自动化 / 管道捕获）时会拒绝启用预测，
    # 此时以下三项必然 FAIL，提示用户到交互终端复核，避免误判为配置错误。
    if ([Console]::IsOutputRedirected) {
        Write-Host "  (提示) 当前会话输出被重定向，PSReadLine 不启用预测；预测相关项请在交互终端复核。"
    }
    $opt = Get-PSReadLineOption
    $source = [string]$opt.PredictionSource
    $view = [string]$opt.PredictionViewStyle
    Add-Result "PredictionSource" ($source -eq "HistoryAndPlugin") $source
    Add-Result "PredictionViewStyle" ($view -eq "ListView") $view

    $ctrlR = @(Get-PSReadLineKeyHandler -Chord 'Ctrl+r' -ErrorAction SilentlyContinue)
    $fzfBound = @($ctrlR | Where-Object { $_.Function -match '(?i)fzf' -or $_.Description -match '(?i)fzf' })
    $hasFzfFn = [bool](Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue)
    if ($hasFzfFn -and $fzfBound.Count -gt 0) {
        Add-Result "Ctrl+R -> PSFzf" $true $fzfBound[0].Function
    } else {
        Add-Result "Ctrl+R -> PSFzf" $false "仍为内置反向搜索（PSFzf 未加载或键位未接管）"
    }
}
# zoxide 0.10+ 的 init 把 z / zi 注册为别名，底层函数是 __zoxide_z / __zoxide_zi。
# 原先用 Get-Command z -CommandType Function 判断：既可能命中无关的 z 模块而误判通过，
# 也会在 zoxide 正常初始化时找不到 z 函数而误判失败，因此直接检查 init 生成的函数。
$zoxideFn = @(Get-Command -Name '__zoxide_*' -CommandType Function -ErrorAction SilentlyContinue)
$zoxideAlias = Get-Alias -Name z -ErrorAction SilentlyContinue
if ($zoxideFn.Count -gt 0 -and $zoxideAlias -and $zoxideAlias.Definition -match '__zoxide_z') {
    Add-Result "zoxide init (z)" $true "z 别名 -> $($zoxideAlias.Definition)"
} elseif ($zoxideFn.Count -gt 0) {
    Add-Result "zoxide init (z)" $true "已注册 $($zoxideFn.Count) 个 __zoxide_* 函数"
} else {
    Add-Result "zoxide init (z)" $false "未检测到 __zoxide_* 函数（检查 PATH 或 profile.ps1 是否加载）"
}
# oh-my-posh 早期 v3 的 init 定义一批 __omp* 函数；v33+ 改为加载 oh-my-posh-core 模块，
# 并定义 *-Posh* 函数（prompt 也由它接管），不再产生 __omp*。两种形态都算已初始化。
$ompFn = @(Get-Command -Name '__omp*' -ErrorAction SilentlyContinue)
$ompCore = Get-Module -Name oh-my-posh-core -ErrorAction SilentlyContinue
$ompPoshFn = @(Get-Command -Name '*Posh*' -CommandType Function -ErrorAction SilentlyContinue)
if ($ompFn.Count -gt 0 -or $ompCore -or $ompPoshFn.Count -gt 0) {
    $detail = if ($ompCore) { "oh-my-posh-core 模块已加载" } else { "$($ompFn.Count) 个 __omp* 函数" }
    Add-Result "oh-my-posh init" $true $detail
} else {
    Add-Result "oh-my-posh init" $false "未检测到 oh-my-posh 初始化痕迹（检查主题路径、PATH 或 profile.ps1 是否加载）"
}

Write-Host "`n==> eza alias"
$alias = Get-Alias ll -ErrorAction SilentlyContinue
if ($alias) {
    Add-Result "alias ll" $true $alias.Definition
} else {
    Add-Result "alias ll" $false "未加载；检查 `$PROFILE 是否 dot-source profile.ps1"
}

Write-Host "`n==> yazi wrappers"
$hasYazi = [bool](Get-Command yazi -ErrorAction SilentlyContinue)
$hasGlow = [bool](Get-Command glow -ErrorAction SilentlyContinue)
foreach ($spec in @(
        @{ Name = "y";  Required = $hasYazi },
        @{ Name = "yg"; Required = ($hasYazi -and $hasGlow) },
        @{ Name = "gw"; Required = $hasGlow }
    )) {
    if (-not $spec.Required) { continue }
    $fn = Get-Command -Name $spec.Name -CommandType Function -ErrorAction SilentlyContinue
    $detail = if ($fn) { "" } else { "未定义；检查 `$PROFILE 是否加载 profile.ps1" }
    Add-Result "wrapper $($spec.Name)" ([bool]$fn) $detail
}

Write-Host "`n==> yazi file(1)"
$fileOne = [Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User')
if (-not $fileOne) { $fileOne = $env:YAZI_FILE_ONE }
if ($fileOne -and (Test-Path -LiteralPath $fileOne -PathType Leaf)) {
    Add-Result "YAZI_FILE_ONE" $true $fileOne
} else {
    $detail = if ($fileOne) { "指向的文件不存在: $fileOne" } else { "未设置；yazi 只能靠扩展名兜底，mime 规则可能失效（重跑 bootstrap.ps1）" }
    Add-Result "YAZI_FILE_ONE" $false $detail
}

Write-Host "`n==> Configs"
$configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME ".config" }
Add-Result "XDG_CONFIG_HOME" $true $configHome
foreach ($name in @("eza", "glow", "helix", "rmux", "yazi", "oh-my-posh")) {
    $path = Join-Path $configHome $name
    if (Test-Path -LiteralPath $path) {
        Add-Result "config/$name" $true
    } else {
        Add-Result "config/$name" $false "缺失: $path"
    }
}
$profileFile = Join-Path $configHome "shell\profile.ps1"
if (Test-Path -LiteralPath $profileFile) {
    Add-Result "config/shell/profile.ps1" $true
} else {
    Add-Result "config/shell/profile.ps1" $false "缺失: $profileFile"
}

Write-Host "`n==> Summary"
foreach ($r in $script:results) {
    $mark = if ($r.Ok) { "PASS" } else { "FAIL" }
    $detail = if ($r.Detail) { " - $($r.Detail)" } else { "" }
    Write-Host ("  [{0}] {1}{2}" -f $mark, $r.Item, $detail)
}

$failed = @($script:results | Where-Object { -not $_.Ok })
if ($failed.Count -gt 0) {
    Write-Host ("`n{0} 项未通过，详见 docs/win11-toolchain.md 排错。" -f $failed.Count)
    exit 1
}
Write-Host "`n全部通过。"
