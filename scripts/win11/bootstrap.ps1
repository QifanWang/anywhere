# 把仓库中的配置链接到 Windows 实际配置目录，并校验工具 PATH
# 优先使用目录联接（Junction），失败时回退为复制；幂等注入 shell profile 引用；可重复运行

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('CurrentUserAllHosts', 'CurrentUserCurrentHost', 'AllUsersAllHosts', 'AllUsersCurrentHost')]
    [string]$ProfileTarget = 'CurrentUserAllHosts',

    [switch]$SkipProfile
)

$ErrorActionPreference = "Stop"

$Repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME ".config" }

function Remove-PathSafely {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -in @('Junction', 'SymbolicLink')) {
        Remove-Item -LiteralPath $Path -Force
        return
    }
    Remove-Item -LiteralPath $Path -Recurse -Force
}

function Get-LinkTarget {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -in @('Junction', 'SymbolicLink')) { return $item.Target }
    return $null
}

function Backup-Existing {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $backup = "$Path.bak"
    Remove-PathSafely -Path $backup
    Rename-Item -LiteralPath $Path -NewName (Split-Path -Leaf $backup) -Force
    Write-Host "[backup] $backup"
}

function Backup-FileStamped {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $backup = "$Path.bak-$stamp"
    Copy-Item -LiteralPath $Path -Destination $backup -Force
    Write-Host "[backup] $backup"
}

function Test-AnywhereProfileReference {
    $paths = @(
        $PROFILE,
        $PROFILE.CurrentUserAllHosts,
        $PROFILE.CurrentUserCurrentHost,
        $PROFILE.AllUsersAllHosts,
        $PROFILE.AllUsersCurrentHost
    )
    foreach ($path in ($paths | Select-Object -Unique)) {
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        try { $text = [System.IO.File]::ReadAllText($path) } catch { continue }
        if ($text -match 'shell[\\/]profile\.ps1') { return $true }
    }
    return $false
}

function Ensure-ProfileReference {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Path)

    if (-not $Path) {
        Write-Warning '未解析到目标 profile 路径，跳过注入。'
        return
    }

    $markerStart = '# >>> anywhere:shell-profile >>>'
    $markerEnd   = '# <<< anywhere:shell-profile <<<'
    $sourceLine  = '. "$env:XDG_CONFIG_HOME\shell\profile.ps1"'

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $existed = Test-Path -LiteralPath $Path -PathType Leaf
    $content = if ($existed) { [System.IO.File]::ReadAllText($Path) } else { '' }

    if ($content -match 'shell[\\/]profile\.ps1') {
        Write-Host "[skip]   $Path 已包含 profile.ps1 引用"
        return
    }

    $lineEnding = if ($content -match "`r`n") { "`r`n" } else { "`n" }
    $block = @($markerStart, $sourceLine, $markerEnd) -join $lineEnding

    $startIndex = $content.IndexOf($markerStart, [System.StringComparison]::Ordinal)
    $endIndex = if ($startIndex -ge 0) { $content.IndexOf($markerEnd, $startIndex, [System.StringComparison]::Ordinal) } else { -1 }
    if ($startIndex -ge 0 -and $endIndex -ge 0) {
        $endIndex += $markerEnd.Length
        $content = $content.Substring(0, $startIndex) + $block + $content.Substring($endIndex)
        $action = '更新'
    } else {
        $prefix = if ($existed -and $content -notmatch "(\r\n|\n)$") { $lineEnding } else { '' }
        $content = $content + $prefix + $block + $lineEnding
        $action = if ($existed) { '注入' } else { '创建' }
    }

    if ($PSCmdlet.ShouldProcess($Path, "$action anywhere shell profile 引用")) {
        if ($existed) { Backup-FileStamped -Path $Path }
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($Path, $content, $utf8NoBom)
        Write-Host "[$action] $Path"
    }
}

function Link-Directory {
    param([string]$Source, [string]$Destination)

    $parent = Split-Path -Parent $Destination
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $existingTarget = Get-LinkTarget -Path $Destination
    if ($existingTarget) {
        if ([string]::Equals(($existingTarget.TrimEnd('\')), ($Source.TrimEnd('\')), 'OrdinalIgnoreCase')) {
            Write-Host "[skip]   $Destination -> $Source"
            return
        }
        Remove-PathSafely -Path $Destination
    }

    Backup-Existing -Path $Destination

    try {
        New-Item -ItemType Junction -Path $Destination -Target $Source -ErrorAction Stop | Out-Null
        Write-Host "[link]   $Destination -> $Source"
        return
    } catch {
        # Junction 不可用，继续尝试 mklink
    }

    $result = & cmd.exe /c mklink /J "$Destination" "$Source" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[mklink] $Destination -> $Source"
        return
    }

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force
    Write-Host "[copy]   $Destination <- $Source"
}

function Link-File {
    param([string]$Source, [string]$Destination)

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Warning "源文件不存在: $Source"
        return
    }

    $parent = Split-Path -Parent $Destination
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $existingTarget = Get-LinkTarget -Path $Destination
    if ($existingTarget) {
        if ([string]::Equals(($existingTarget.TrimEnd('\')), ($Source.TrimEnd('\')), 'OrdinalIgnoreCase')) {
            Write-Host "[skip]   $Destination -> $Source"
            return
        }
        Remove-PathSafely -Path $Destination
    } else {
        Backup-Existing -Path $Destination
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -ErrorAction Stop | Out-Null
        Write-Host "[link]   $Destination -> $Source"
        return
    } catch {
        # 符号链接需要管理员/开发者模式，回退为复制
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "[copy]   $Destination <- $Source"
}

function Join-PathEntries {
    param([string[]]$PathValues)
    $seen = @{}
    $result = @()
    foreach ($value in $PathValues) {
        if (-not $value) { continue }
        foreach ($entry in ($value -split ';' | Where-Object { $_.Trim() })) {
            $trimmed = $entry.Trim().TrimEnd('\')
            $key = $trimmed.ToLowerInvariant()
            if (-not $seen.ContainsKey($key)) {
                $seen[$key] = $true
                $result += $trimmed
            }
        }
    }
    return ($result -join ';')
}

function Refresh-ProcessPath {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $env:Path = Join-PathEntries @($userPath, $machinePath, $env:Path)
}

function Find-ToolExecutable {
    param([string]$Name, [string]$WingetId)

    $candidateDirs = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'),
        (Join-Path $HOME '.cargo\bin'),
        (Join-Path $HOME 'go\bin')
    )

    $packagesRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path -LiteralPath $packagesRoot) {
        $packageDirs = Get-ChildItem -LiteralPath $packagesRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "$WingetId*" } |
            Sort-Object LastWriteTimeUtc -Descending
        foreach ($dirInfo in $packageDirs) { $candidateDirs += $dirInfo.FullName }
    }

    $exeName = "$Name.exe"
    foreach ($dir in $candidateDirs) {
        if (-not $dir -or -not (Test-Path -LiteralPath $dir)) { continue }
        $hits = Get-ChildItem -LiteralPath $dir -Filter $exeName -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\libexec\\' } |
            Sort-Object { $_.FullName.Split('\').Count }
        if ($hits) { return $hits[0].FullName }
    }
    return $null
}

function Add-UserPathEntry {
    param([string]$Directory)
    $target = $Directory.Trim().TrimEnd('\')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' |
        Where-Object { $_.Trim() } |
        Where-Object { -not [string]::Equals($_.Trim().TrimEnd('\'), $target, 'OrdinalIgnoreCase') })
    $newPath = (@($target) + $entries) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    $env:Path = Join-PathEntries @($target, $env:Path)
    Write-Host "[path]   added: $target"
}

function Assert-ToolPath {
    param([string]$Name, [string]$WingetId)

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("[path]   {0}: OK -> {1}" -f $Name, $cmd.Source)
        return
    }

    $exe = Find-ToolExecutable -Name $Name -WingetId $WingetId
    if (-not $exe) {
        Write-Warning ("{0} 不在 PATH，且未在 winget 安装目录找到；请先运行 install.ps1。" -f $Name)
        return
    }

    Add-UserPathEntry -Directory (Split-Path -Parent $exe)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("[path]   {0}: OK -> {1}" -f $Name, $cmd.Source)
    } else {
        Write-Warning ("{0} 已写入用户 PATH，但当前会话未生效；请重开终端。" -f $Name)
    }
}

Write-Host "==> Repository: $Repo"

New-Item -ItemType Directory -Path $configHome -Force | Out-Null
[Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $configHome, 'User')
$env:XDG_CONFIG_HOME = $configHome
Write-Host "==> XDG_CONFIG_HOME: $configHome"

$linkMap = @(
    @{ Source = "eza";        Xdg = "eza";        AppData = "eza" },
    @{ Source = "glow";       Xdg = "glow";       AppData = "glow" },
    @{ Source = "helix";      Xdg = "helix";      AppData = "helix" },
    @{ Source = "rmux";       Xdg = "rmux";       AppData = "rmux" },
    @{ Source = "yazi";       Xdg = "yazi";       AppData = "yazi\config" },
    @{ Source = "oh-my-posh"; Xdg = "oh-my-posh"; AppData = "oh-my-posh" }
)

Write-Host "`n==> Linking configs"
foreach ($item in $linkMap) {
    $source = Join-Path $Repo ("config\" + $item.Source)
    Link-Directory -Source $source -Destination (Join-Path $configHome $item.Xdg)
    if ($env:APPDATA) {
        Link-Directory -Source $source -Destination (Join-Path $env:APPDATA $item.AppData)
    }
}
# config/shell/profile.ps1 是单文件，单独链接；config/shell/env.sh 只用于其他平台。
Link-File -Source (Join-Path $Repo "config\shell\profile.ps1") -Destination (Join-Path $configHome "shell\profile.ps1")

Write-Host "`n==> PowerShell profile"
if ($SkipProfile) {
    Write-Host "[skip]   -SkipProfile 已指定，未修改任何 profile"
} elseif (Test-AnywhereProfileReference) {
    Write-Host "[skip]   已在某个 `$PROFILE 中找到 shell\profile.ps1 引用"
} else {
    $targetProfile = switch ($ProfileTarget) {
        'CurrentUserAllHosts'   { $PROFILE.CurrentUserAllHosts }
        'CurrentUserCurrentHost' { $PROFILE.CurrentUserCurrentHost }
        'AllUsersAllHosts'      { $PROFILE.AllUsersAllHosts }
        'AllUsersCurrentHost'   { $PROFILE.AllUsersCurrentHost }
    }
    if ($ProfileTarget -like 'AllUsers*') {
        Write-Warning "$ProfileTarget 通常需要管理员权限；如失败请改用 CurrentUser* 目标。"
    }
    Ensure-ProfileReference -Path $targetProfile
}

Write-Host "`n==> Checking PATH"
Refresh-ProcessPath
$tools = @(
    @{ Name = "rmux";       WingetId = "Helvesec.RMUX" },
    @{ Name = "eza";        WingetId = "eza-community.eza" },
    @{ Name = "glow";       WingetId = "charmbracelet.glow" },
    @{ Name = "yazi";       WingetId = "sxyazi.yazi" },
    @{ Name = "hx";         WingetId = "Helix.Helix" },
    @{ Name = "fd";         WingetId = "sharkdp.fd" },
    @{ Name = "fzf";        WingetId = "junegunn.fzf" },
    @{ Name = "lazygit";    WingetId = "JesseDuffield.lazygit" },
    @{ Name = "zoxide";     WingetId = "ajeetdsouza.zoxide" },
    @{ Name = "oh-my-posh"; WingetId = "JanDeDobbeleer.OhMyPosh" }
)
foreach ($tool in $tools) {
    Assert-ToolPath -Name $tool.Name -WingetId $tool.WingetId
}

Write-Host "`n==> 接下来"
Write-Host "  新开 PowerShell 7 终端后运行 .\scripts\win11\verify.ps1"
if ($SkipProfile) {
    Write-Host '  使用 -SkipProfile 时请自行在合适的 $PROFILE 中加入：. "$env:XDG_CONFIG_HOME\shell\profile.ps1"'
}
Write-Host "`n完成。"
