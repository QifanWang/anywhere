[CmdletBinding()]
param([switch]$Yes)

$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
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

$plan = @(
    @{ Label = "rmux"; Scoop = "rmux"; Winget = "Helvesec.RMUX";         Choco = "rmux" },
    @{ Label = "eza";  Scoop = "eza";  Winget = "eza.eza";               Choco = "eza" },
    @{ Label = "glow"; Scoop = "glow"; Winget = "charmbracelet.glow";    Choco = "glow" },
    @{ Label = "yazi"; Scoop = "yazi"; Winget = $null;                   Choco = "yazi" }
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
