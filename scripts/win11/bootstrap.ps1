# 把仓库中的配置链接到 Windows 实际配置目录，并校验工具 PATH
# 优先使用目录联接（Junction），失败时回退为复制；可重复运行

[CmdletBinding()]
param()

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
    @{ Source = "eza";   Xdg = "eza";   AppData = "eza" },
    @{ Source = "glow";  Xdg = "glow";  AppData = "glow" },
    @{ Source = "helix"; Xdg = "helix"; AppData = "helix" },
    @{ Source = "rmux";  Xdg = "rmux";  AppData = "rmux" },
    @{ Source = "yazi";  Xdg = "yazi";  AppData = "yazi\config" }
)

Write-Host "`n==> Linking configs"
foreach ($item in $linkMap) {
    $source = Join-Path $Repo ("config\" + $item.Source)
    Link-Directory -Source $source -Destination (Join-Path $configHome $item.Xdg)
    if ($env:APPDATA) {
        Link-Directory -Source $source -Destination (Join-Path $env:APPDATA $item.AppData)
    }
}
# config/tmux 与 config/shell/env.sh 只用于其他平台，Windows 不链接。

Write-Host "`n==> Checking PATH"
Refresh-ProcessPath
$tools = @(
    @{ Name = "rmux";    WingetId = "Helvesec.RMUX" },
    @{ Name = "eza";     WingetId = "eza-community.eza" },
    @{ Name = "glow";    WingetId = "charmbracelet.glow" },
    @{ Name = "yazi";    WingetId = "sxyazi.yazi" },
    @{ Name = "hx";      WingetId = "Helix.Helix" },
    @{ Name = "fd";      WingetId = "sharkdp.fd" },
    @{ Name = "fzf";     WingetId = "junegunn.fzf" },
    @{ Name = "lazygit"; WingetId = "JesseDuffield.lazygit" }
)
foreach ($tool in $tools) {
    Assert-ToolPath -Name $tool.Name -WingetId $tool.WingetId
}

Write-Host "`n==> 接下来（只需一次）"
Write-Host "  在 PowerShell 配置文件（`$PROFILE）中加入:"
Write-Host ("    . '{0}'" -f (Join-Path $configHome "eza\aliases.ps1").Replace("'", "''"))
Write-Host "  验证: 重开终端后运行 .\\scripts\\win11\\verify.ps1"
Write-Host "`n完成。"
