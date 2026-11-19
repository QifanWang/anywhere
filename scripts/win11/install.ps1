[CmdletBinding()]
param([switch]$Yes)

$ErrorActionPreference = "Stop"

# winget 0x8A15002B：已安装且没有可用升级，在 PowerShell 中表现为 -1978335189
$Script:WingetNoUpgradeExitCode = -1978335189

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-WingetPackageInstalled {
    param([string]$WingetId)
    $listed = (& winget list --id $WingetId -e --disable-interactivity 2>$null) -join "`n"
    return ($listed -match [regex]::Escape($WingetId))
}

function Install-Package {
    param(
        [string]$Label,
        [string]$WingetId
    )

    if (Test-WingetPackageInstalled -WingetId $WingetId) {
        Write-Host "  已安装，检查是否有可用升级"
    } else {
        Write-Host "  未安装，执行安装"
    }

    # winget install 对已安装包会自动尝试升级；无升级时返回 0x8A15002B，应视为成功。
    & winget install --id $WingetId -e --accept-source-agreements --accept-package-agreements --disable-interactivity
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq $Script:WingetNoUpgradeExitCode) {
        Write-Host "  已是最新版本，无需升级"
        return
    }
    if ($exitCode -ne 0) {
        throw ("安装/升级 {0} 失败（winget 退出码 {1}）。" -f $Label, $exitCode)
    }
}

Write-Host "==> Checking package manager"
if (-not (Test-CommandExists "winget")) {
    throw "未找到 winget。请先运行 .\\scripts\\win11\\prepare.ps1 完成前置准备，详见 docs/win11-toolchain.md。"
}
Write-Host ("  winget {0}" -f ((& winget --version) -join " "))

$plan = @(
    @{ Label = "rmux";    Winget = "Helvesec.RMUX" },
    @{ Label = "eza";     Winget = "eza-community.eza" },
    @{ Label = "glow";    Winget = "charmbracelet.glow" },
    @{ Label = "yazi";    Winget = "sxyazi.yazi" },
    @{ Label = "helix";   Winget = "Helix.Helix" },
    @{ Label = "fd";      Winget = "sharkdp.fd" },
    @{ Label = "fzf";     Winget = "junegunn.fzf" },
    @{ Label = "lazygit"; Winget = "JesseDuffield.lazygit" }
)

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
    Install-Package -Label $item.Label -WingetId $item.Winget
}

Write-Host "`n==> Multiplexer"
Write-Host "  win11 使用 RMUX（原生 ConPTY，无需 WSL）；tmux 仅保留给其他平台"

Write-Host "`n==> Verification"
foreach ($name in @("rmux", "eza", "glow", "yazi", "hx", "fd", "fzf", "lazygit")) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host ("  {0}: OK" -f $name)
    } else {
        Write-Host ("  {0}: NOT FOUND (可能需要重开终端)" -f $name)
    }
}

Write-Host "`n完成。下一步: .\\scripts\\win11\\bootstrap.ps1"
