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
# zoxide init 注册 z 函数；用函数而非别名判断
$cmdZ = Get-Command z -CommandType Function -ErrorAction SilentlyContinue
if ($cmdZ) {
    Add-Result "zoxide init (z)" $true
} else {
    Add-Result "zoxide init (z)" $false "z 函数不存在；检查 profile.ps1 是否加载"
}
# oh-my-posh v3 通过 init 脚本重写 prompt 函数；Set-PoshPrompt 是旧版命令，不能用来判断。
# init 输出会定义一批 __omp* 函数，比匹配 prompt 定义更稳定。
$ompFn = @(Get-Command -Name '__omp*' -ErrorAction SilentlyContinue)
if ($ompFn.Count -gt 0) {
    Add-Result "oh-my-posh init" $true "oh-my-posh 已接管（$($ompFn.Count) 个 __omp* 函数）"
} else {
    Add-Result "oh-my-posh init" $false "未检测到 __omp* 函数（检查主题路径或 profile.ps1 是否加载）"
}

Write-Host "`n==> eza alias"
$alias = Get-Alias ll -ErrorAction SilentlyContinue
if ($alias) {
    Add-Result "alias ll" $true $alias.Definition
} else {
    Add-Result "alias ll" $false "未加载；检查 `$PROFILE 是否 dot-source profile.ps1"
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
