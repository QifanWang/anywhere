# 3.1 前置准备：检查并配置包管理器（winget），安装终端（Windows Terminal）
# 要求在 PowerShell 7 中运行；字体需手动下载安装，脚本仅给出指引。可重复运行。

[CmdletBinding()]
param([switch]$Yes)

$ErrorActionPreference = "Stop"

# 代理仅设置在当前 PowerShell 进程；同一会话后续脚本及其子进程会继承。
$env:HTTP_PROXY = "http://127.0.0.1:7890"
$env:HTTPS_PROXY = "http://127.0.0.1:7890"

# winget 0x8A15002B：已安装且没有可用升级，在 PowerShell 中表现为 -1978335189
$Script:WingetNoUpgradeExitCode = -1978335189

$Script:WingetMirrorUrl = "https://mirrors.cernet.edu.cn/winget-source"
$Script:WingetMirrorHosts = @(
    "mirrors.cernet.edu.cn",
    "mirrors.ustc.edu.cn",
    "mirrors.tuna.tsinghua.edu.cn",
    "mirror.nju.edu.cn",
    "mirrors.zju.edu.cn",
    "mirrors.xjtu.edu.cn"
)

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-IsElevated {
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WingetSourceUrl {
    $detail = (& winget source list -n winget 2>$null) -join "`n"
    if ($detail -match '(?im)^\s*\S+\s+(https?://\S+)') {
        return $Matches[1]
    }
    return $null
}

function Test-IsMainlandWingetMirror {
    param([string]$Url)
    if (-not $Url) { return $false }
    foreach ($hostName in $Script:WingetMirrorHosts) {
        if ($Url.Contains($hostName)) { return $true }
    }
    return $false
}

function Ensure-WingetMirror {
    $current = Get-WingetSourceUrl
    if (Test-IsMainlandWingetMirror $current) {
        Write-Host ("  winget 源已使用大陆镜像: {0}" -f $current)
        return
    }

    $reason = if ($current) { "当前源为 $current" } else { "未找到名为 winget 的源" }
    if (-not (Test-IsElevated)) {
        throw ("{0}，不是大陆镜像。修改 winget 源需要管理员权限；请以管理员身份运行 PowerShell 后重试，或手动执行: winget source remove winget; winget source add winget {1} --trust-level trusted; winget source update" -f $reason, $Script:WingetMirrorUrl)
    }

    Write-Host ("==> 配置 winget 大陆镜像源: {0}" -f $Script:WingetMirrorUrl)
    if ($current) {
        & winget source remove winget | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "移除旧 winget 源失败（退出码 $LASTEXITCODE）。" }
    }
    & winget source add winget $Script:WingetMirrorUrl --trust-level trusted --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "添加 winget 镜像源失败（退出码 $LASTEXITCODE）。" }
    & winget source update
    if ($LASTEXITCODE -ne 0) { Write-Warning "winget 源更新失败，安装时会自动重试。" }
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

Write-Host "==> Checking shell"
if ($PSVersionTable.PSVersion.Major -ne 7) {
    throw ("本脚本要求在 PowerShell 7 中运行，当前为 {0}。请先安装并切换到 PowerShell 7。" -f $PSVersionTable.PSVersion)
}
Write-Host ("  PowerShell {0}" -f $PSVersionTable.PSVersion)

Write-Host "`n==> Checking package manager"
if (-not (Test-CommandExists "winget")) {
    throw "未找到 winget。请先安装 Microsoft App Installer，详见 docs/win11-toolchain.md。"
}
Write-Host ("  winget {0}" -f ((& winget --version) -join " "))
Ensure-WingetMirror

$plan = @(
    @{ Label = "Windows Terminal"; Winget = "Microsoft.WindowsTerminal" }
)

Write-Host "`n==> Install plan (terminal)"
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

Write-Host "`n==> Font (manual step)"
Write-Host "  Nerd Font 需手动下载安装: https://www.nerdfonts.com/"
Write-Host "  例如 FiraCode Nerd Font；在 Windows Terminal 中设为 '* Nerd Font Mono' 并开启 GPU 渲染。"

Write-Host "`n==> Verification"
if (Get-Command wt -ErrorAction SilentlyContinue) {
    Write-Host "  Windows Terminal: OK (wt)"
} else {
    Write-Host "  Windows Terminal: NOT FOUND (可能需要重开终端)"
}

Write-Host "`n完成。下一步: .\\scripts\\win11\\install.ps1"
