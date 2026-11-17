# 把仓库中的配置链接到 Windows 实际配置目录
# 优先使用目录联接（Junction），失败时回退为复制

$ErrorActionPreference = "Stop"

$Repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Backup-Existing {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $backup = "$Path.bak"
    if (Test-Path -LiteralPath $backup) {
        Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue
    }
    Rename-Item -LiteralPath $Path -NewName (Split-Path -Leaf $backup) -Force
    Write-Host "[backup] $backup"
}

function Link-Directory {
    param([string]$Source, [string]$Destination)

    $parent = Split-Path -Parent $Destination
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
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

Write-Host "==> Repository: $Repo"

$configHome = Join-Path $HOME ".config"
New-Item -ItemType Directory -Path $configHome -Force | Out-Null

Link-Directory -Source (Join-Path $Repo "config\rmux") -Destination (Join-Path $configHome "rmux")
Link-Directory -Source (Join-Path $Repo "config\glow") -Destination (Join-Path $configHome "glow")
Link-Directory -Source (Join-Path $Repo "config\yazi") -Destination (Join-Path $configHome "yazi")

if ($env:APPDATA) {
    Link-Directory -Source (Join-Path $Repo "config\rmux") -Destination (Join-Path $env:APPDATA "rmux")
    Link-Directory -Source (Join-Path $Repo "config\glow") -Destination (Join-Path $env:APPDATA "glow")
    Link-Directory -Source (Join-Path $Repo "config\yazi") -Destination (Join-Path $env:APPDATA "yazi\config")
}

Write-Host "`n==> 接下来（只需一次）"
Write-Host "  1) 在 PowerShell 配置文件中加入:"
Write-Host ("     `$env:XDG_CONFIG_HOME = '{0}'" -f $configHome.Replace("'", "''"))
Write-Host ("     . '{0}'" -f (Join-Path $Repo "config\eza\aliases.ps1").Replace("'", "''"))
Write-Host "  2) 验证 RMUX 已读到配置:"
Write-Host "     rmux -V ; rmux list-keys -N"
Write-Host "`n完成。"
