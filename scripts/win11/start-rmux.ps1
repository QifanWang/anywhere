# 快速启动一个命名 rmux 会话：新建 Windows Terminal 窗口、左右分屏、attach 进去。
# 要求 PowerShell 7 + wt + rmux 在 PATH 中。
#
# 用法（在仓库根目录运行）：
#   .\scripts\win11\start-rmux.ps1                        # 会话名 dev，起始目录 = 当前目录
#   .\scripts\win11\start-rmux.ps1 -Name work              # 指定会话名 work
#   .\scripts\win11\start-rmux.ps1 -Name demo -Directory D:\proj -Title "Demo"
#   .\scripts\win11\start-rmux.ps1 -Name dev -NoWindow     # 不开新窗口，当前终端 attach（无 wt 时）
#
# 会话名不能含空白；同名会话已存在会报错（先 rmux kill-session -t <name> 或换名）。
# 详见 docs/win11-toolchain.md 与 docs/cheatsheet/rmux.md。

[CmdletBinding()]
param(
    # rmux 会话名（用于 attach / 重命名，rmux 会话名不可含空白）
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Name = "dev",

    # 新会话的起始目录（默认当前 PowerShell 的 location）
    [string]$Directory,

    # Windows Terminal 窗口标题（默认 "rmux: <Name>"）
    [string]$Title,

    # 不另开窗口：在当前终端建会话 + 分屏 + attach（调试/无 wt 时用）
    [switch]$NoWindow
)

$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([string]$CommandName)
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

# rmux 会话名不允许空白；引号/分号会破坏 attach 命令行，一并拒绝。
if ($Name -match '\s') {
    throw "会话名不能包含空白: '$Name'"
}

# 确定起始目录：显式参数优先，否则用当前 location；校验存在并取绝对路径。
$startDir = if ($Directory) { $Directory } else { (Get-Location).ProviderPath }
if (-not (Test-Path -LiteralPath $startDir -PathType Container)) {
    throw "起始目录不存在: $startDir"
}
$startDir = (Resolve-Path -LiteralPath $startDir).ProviderPath

# 确定窗口标题。
if (-not $Title) { $Title = "rmux: $Name" }

# --- 前置检查 ---
Write-Host "==> Checking tools"
if (-not (Test-CommandExists "rmux")) {
    throw "未找到 rmux。请先运行 .\\scripts\\win11\\install.ps1，详见 docs/win11-toolchain.md。"
}
if (-not $NoWindow -and -not (Test-CommandExists "wt")) {
    throw "未找到 wt（Windows Terminal）。请安装后重试，或加 -NoWindow 在当前终端启动。"
}
Write-Host ("  rmux {0}" -f ((& rmux -V) -join " "))
Write-Host ("  dir  {0}" -f $startDir)
Write-Host ("  name {0}" -f $Name)

# --- 同名会话处理 ---
& rmux has-session -t $Name 2>$null
if ($LASTEXITCODE -eq 0) {
    throw ("会话 '{0}' 已存在。请换一个 -Name，或先执行: rmux kill-session -t {0}" -f $Name)
}

# --- 建会话 + 左右分屏（detached，先建好再 attach，避免在交互里敲命令）---
Write-Host "`n==> Creating session '$Name' with a left/right split"
& rmux new-session -d -s $Name -c $startDir
if ($LASTEXITCODE -ne 0) { throw "创建 rmux 会话失败（退出码 $LASTEXITCODE）。" }
& rmux split-window -h -t $Name -c $startDir
if ($LASTEXITCODE -ne 0) {
    & rmux kill-session -t $Name 2>$null
    throw "左右分屏失败（退出码 $LASTEXITCODE），已清理会话。"
}

$panes = @(& rmux list-panes -t $Name -F '#{pane_index}' 2>$null)
Write-Host ("  已创建 {0} 个面板（左右分屏）" -f $panes.Count)

$attachCmd = "rmux attach -t $Name"

if ($NoWindow) {
    Write-Host "`n==> Attaching in current terminal"
    & rmux attach -t $Name
    exit $LASTEXITCODE
}

# --- 在新 Windows Terminal 窗口里 attach ---
# -w new 开新窗口；--title 设标题；--suppressApplicationTitle 防止被程序改写；
# attach 命令作为 pwsh -Command 传入，只有会话名一个变量，无复杂转义。
Write-Host "`n==> Launching new Windows Terminal window: $Title"
$wtArgs = @(
    '-w', 'new',
    'new-tab',
    '--title', $Title,
    '--suppressApplicationTitle',
    '-d', $startDir,
    'pwsh', '-NoProfile', '-Command', $attachCmd
)
& wt @wtArgs
if ($LASTEXITCODE -ne 0) {
    throw "启动 Windows Terminal 窗口失败（退出码 $LASTEXITCODE）。会话 '$Name' 仍在，可用 'rmux attach -t $Name' 接入。"
}

Write-Host "`n完成。会话 '$Name' 已在独立窗口打开（左右分屏）。"
Write-Host "  重新接入:   rmux attach -t $Name"
Write-Host "  结束会话:   rmux kill-session -t $Name"
