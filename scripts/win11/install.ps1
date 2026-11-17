[CmdletBinding()]
param([switch]$Yes)

$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-IsElevated {
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PendingReboot {
    $rebootKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    )
    foreach ($key in $rebootKeys) {
        if (Test-Path -LiteralPath $key) { return $true }
    }
    $sessionManager = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction SilentlyContinue
    return [bool]($sessionManager -and $sessionManager.PendingFileRenameOperations)
}

function Install-Package {
    param(
        [string]$ScoopName,
        [string]$WingetId,
        [string]$ChocoName
    )

    if (Test-CommandExists "scoop") {
        scoop install $ScoopName
        return
    }
    if ((Test-CommandExists "winget") -and $WingetId) {
        winget install --id $WingetId -e --accept-source-agreements --accept-package-agreements
        return
    }
    if ((Test-CommandExists "choco") -and $ChocoName) {
        if (-not (Test-IsElevated)) {
            Write-Warning "当前不是提升的 PowerShell；Chocolatey 多数包需要管理员权限，建议改用 winget / scoop，或以管理员身份重开终端后重试。"
        }
        choco install $ChocoName -y
        return
    }
    Write-Warning "No matching package manager for $ScoopName; skipped."
}

Write-Host "==> Checking package managers"
$hasScoop  = Test-CommandExists "scoop"
$hasWinget = Test-CommandExists "winget"
$hasChoco  = Test-CommandExists "choco"

if (-not ($hasScoop -or $hasWinget -or $hasChoco)) {
    throw "未找到 scoop / winget / choco。请先安装其中一个包管理器，详见 docs/win11/INSTALL.md。"
}
Write-Host ("  scoop={0} winget={1} choco={2}" -f $hasScoop, $hasWinget, $hasChoco)

if (Test-PendingReboot) {
    Write-Warning "检测到系统有待重启请求。Chocolatey 默认会忽略它；建议先重启再安装，避免后续步骤异常。"
}

$plan = @(
    @{ Label = "rmux"; Scoop = "rmux"; Winget = "Helvesec.RMUX";         Choco = "rmux" },
    @{ Label = "eza";  Scoop = "eza";  Winget = "eza.eza";               Choco = "eza" },
    @{ Label = "glow"; Scoop = "glow"; Winget = "charmbracelet.glow";    Choco = "glow" },
    @{ Label = "yazi"; Scoop = "yazi"; Winget = "sxyazi.yazi";           Choco = "yazi" }
)

if ($hasScoop) {
    $buckets = (& scoop bucket list 2>$null) -join "`n"
    if ($buckets -notmatch '(?m)^\s*rmux\s') {
        Write-Host "`n==> Adding scoop bucket: rmux"
        scoop bucket add rmux https://github.com/Helvesec/scoop-rmux
    }
}

Write-Host "`n==> Install plan"
$plan | ForEach-Object { Write-Host ("  - {0}" -f $_.Label) }

if (-not $Yes) {
    $answer = Read-Host "继续安装? [y/N]"
    if ($answer -notmatch '^(y|yes)$') {
        Write-Host "已取消。"
        exit 0
    }
}

foreach ($item in $plan) {
    Write-Host "`n==> Installing $($item.Label)"
    Install-Package -ScoopName $item.Scoop -WingetId $item.Winget -ChocoName $item.Choco
}

Write-Host "`n==> Multiplexer"
Write-Host "  win11 使用 RMUX（原生 ConPTY，无需 WSL）；tmux 仅保留给其他平台"

Write-Host "`n==> Verification"
foreach ($name in @("rmux", "eza", "glow", "yazi")) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("  {0}: OK" -f $name)
    } else {
        Write-Host ("  {0}: NOT FOUND (可能需要重开终端)" -f $name)
    }
}

Write-Host "`n完成。下一步: .\\scripts\\win11\\bootstrap.ps1"
