# 在当前 rmux 会话里新建一个「命名 window」并左右分屏，随后切到该 window。
# 前提：本脚本在 rmux 会话内运行（当前 shell 的 pane 属于某个 session）。
# 命名给新 window 的名字（显示在 rmux 状态栏）；默认不另开 Windows Terminal 窗口。
#
# 用法（在仓库根目录、rmux 会话内运行）：
#   .\scripts\win11\start-rmux.ps1                        # 新 window 名 dev，起始目录 = 当前目录
#   .\scripts\win11\start-rmux.ps1 -Name work              # 新 window 名 work
#   .\scripts\win11\start-rmux.ps1 -Name demo -Directory D:\proj
#   .\scripts\win11\start-rmux.ps1 -Name demo -NewTerminalWindow   # 另开 Windows Terminal 窗口接入
#
# -Name 是 window 名（可含空格，rmux 会加引号）；rmux 对 -n 命名的 window 自动关掉
# automatic-rename，故名字持久。详见 docs/win11-toolchain.md 与 docs/cheatsheet/rmux.md。

[CmdletBinding()]
param(
    # 新 window 的名字（显示在 rmux 状态栏）
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Name = "dev",

    # 新 window 的起始目录（默认当前 PowerShell 的 location）
    [string]$Directory,

    # 另开一个 Windows Terminal 窗口接入该 session（默认不另开，直接切到新 window）
    [switch]$NewTerminalWindow
)

$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([string]$CommandName)
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

# --- 前置检查 ---
Write-Host "==> Checking tools"
if (-not (Test-CommandExists "rmux")) {
    throw "未找到 rmux。请先运行 .\\scripts\\win11\\install.ps1，详见 docs/win11-toolchain.md。"
}

# 必须在 rmux 会话内运行：靠 RMUX / TMUX / RMUX_PANE 环境变量判断（rmux 会注入这些）。
if (-not $env:RMUX -and -not $env:TMUX) {
    throw "当前不在 rmux 会话内（未检测到 RMUX/TMUX 环境变量）。请先进入 rmux 会话再运行本脚本。"
}
if ($NewTerminalWindow -and -not (Test-CommandExists "wt")) {
    throw "未找到 wt（Windows Terminal），无法使用 -NewTerminalWindow。请安装后重试。"
}

# 当前 session（脚本所在 pane 所属的会话），新 window 建在它里面。
$sessionId = (& rmux display-message -p '#{session_id}' 2>&1).Trim()
if (-not $sessionId) { throw "无法获取当前 rmux session id。" }
$sessionName = (& rmux display-message -p '#{session_name}' 2>&1).Trim()

# 起始目录：显式参数优先，否则取当前 location（rmux 会话里 cd 到哪就从哪开）。
$startDir = if ($Directory) { $Directory } else { (Get-Location).ProviderPath }
if (-not (Test-Path -LiteralPath $startDir -PathType Container)) {
    throw "起始目录不存在: $startDir"
}
$startDir = (Resolve-Path -LiteralPath $startDir).ProviderPath

Write-Host ("  rmux    {0}" -f ((& rmux -V) -join " "))
Write-Host ("  session {0} ({1})" -f $sessionName, $sessionId)
Write-Host ("  window  {0}" -f $Name)
Write-Host ("  dir     {0}" -f $startDir)

# --- 新建命名 window（detached，先建好再切换）---
# -P -F 取回新 window id，后续命令用它精确定位（不受重命名/重名影响）。
Write-Host "`n==> Creating window '$Name' in session $sessionName"
$windowId = (& rmux new-window -d -P -F '#{window_id}' -t $sessionId -n $Name -c $startDir 2>&1).Trim()
if (-not $windowId -or $LASTEXITCODE -ne 0) {
    throw "新建 window '$Name' 失败（返回值 '$windowId'，退出码 $LASTEXITCODE）。"
}

# --- 左右分屏 ---
& rmux split-window -h -t $windowId -c $startDir
if ($LASTEXITCODE -ne 0) {
    & rmux kill-window -t $windowId 2>$null
    throw "左右分屏失败（退出码 $LASTEXITCODE），已清理新建的 window。"
}
$panes = @(& rmux list-panes -t $windowId -F '#{pane_index}' 2>$null)
Write-Host ("  已创建 {0} 个面板（左右分屏）" -f $panes.Count)

# 先把 session 的 active window 切到新 window：这样无论默认路径还是 -NewTerminalWindow，
# 当前客户端 / 新 attach 的客户端都会落在新 window 上。
Write-Host "`n==> Switching to window '$Name'"
& rmux select-window -t $windowId
if ($LASTEXITCODE -ne 0) { throw "切换到 window '$Name' 失败（退出码 $LASTEXITCODE）。" }

if ($NewTerminalWindow) {
    # 另开 Windows Terminal 窗口接入该 session。active window 已切好，单纯 attach 即可，
    # 不在 -Command 里拼 rmux 的 \;（那是 rmux 语法，会被 pwsh 当成语句分隔符拆开）。
    Write-Host "`n==> Launching new Windows Terminal window: $Name"
    $wtArgs = @(
        '-w', 'new',
        'new-tab',
        '--title', "rmux: $Name",
        '--suppressApplicationTitle',
        '-d', $startDir,
        'pwsh', '-NoProfile', '-Command', "rmux attach -t $sessionName"
    )
    & wt @wtArgs
    if ($LASTEXITCODE -ne 0) {
        throw "启动 Windows Terminal 窗口失败（退出码 $LASTEXITCODE）。window '$Name' 已在 session $sessionName 中且为 active，可用 rmux attach -t $sessionName 接入。"
    }
}

Write-Host "`n完成。window '$Name' 已在 session $sessionName 中打开（左右分屏）。"
Write-Host "  切入该 window:  rmux select-window -t $windowId"
Write-Host "  关闭该 window:  rmux kill-window -t $windowId"
