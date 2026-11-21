# anywhere / yazi: Windows 下渲染 markdown（预览插件与 o 精读共用）
# 用法:
#   glow.ps1 <file> [width]          预览模式：输出渲染结果，供 yazi 预览插件读取
#   glow.ps1 <file> [width] -Pager   精读模式：全屏分页，q 退出回到 yazi（对应 Unix 的 less -R）
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [int]$Width = 0,
    [switch]$Pager
)

$ErrorActionPreference = 'Stop'

# yazi 经 cmd /C 启动的子进程可能继承 GBK 代码页，导致 glow 的 UTF-8 输出被按 GBK 解码
# 后写出成乱码；这里显式固定为 UTF-8（预览模式与分页模式都受益）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { exit 1 }

if ($Width -le 0) {
    try { $Width = [Console]::WindowWidth } catch { }
    if ($Width -le 0) {
        try { $Width = $Host.UI.RawUI.WindowSize.Width } catch { }
    }
}

# glow v3 只在 stdin 渲染；-s dark 强制彩色（stdout 被管道接走时不会自动染色）
$glowArgs = @('-s', 'dark')
if ($Width -gt 0) { $glowArgs += @('-w', [string]$Width) }
$glowArgs += '-'

$text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
$lines = @($text | glow @glowArgs | ForEach-Object {
    # 剥掉 OSC 8 超链接；yazi 的 ANSI 解析器会把结尾 BEL 显示成 ^G
    $_ -replace "\u001b\]8;[^\u0007]*\u0007", '' -replace "\u0007", ''
})

if (-not $Pager) {
    $lines | ForEach-Object { Write-Output $_ }
    return
}

# --- 全屏分页：Unix 侧 less -R 的等价物 ---
$height = 0
try { $height = [Console]::WindowHeight } catch { }
if ($height -le 0) {
    try { $height = $Host.UI.RawUI.WindowSize.Height } catch { }
}
if ($height -le 0) { $height = 24 }
$pageSize = [Math]::Max(1, $height - 1)   # 末行留给状态提示

$top = 0
while ($true) {
    try { [Console]::Clear() } catch { }

    $end = [Math]::Min($top + $pageSize - 1, $lines.Count - 1)
    for ($i = $top; $i -le $end; $i++) {
        [Console]::WriteLine($lines[$i])
    }

    $more = $end -lt $lines.Count - 1
    $hint = if ($more) {
        "-- More --  [space/f] next  [b] back  [j/k] line  [q] quit"
    } else {
        "-- END --  [b] back  [q] quit"
    }
    [Console]::WriteLine($hint)

    try {
        $key = [Console]::ReadKey($true)
    } catch {
        break   # 非交互终端无法读键，直接退出，避免死循环
    }

    $k = $key.Key.ToString()
    if ($k -eq 'Q' -or $k -eq 'Escape') { break }

    if ($k -in @('Spacebar', 'Enter', 'PageDown', 'F')) {
        $top = $end + 1
    } elseif ($k -eq 'B' -or $k -eq 'PageUp') {
        $top = [Math]::Max(0, $top - $pageSize)
    } elseif ($k -eq 'J' -or $k -eq 'ArrowDown') {
        $top = $top + 1
    } elseif ($k -eq 'K' -or $k -eq 'ArrowUp') {
        $top = $top - 1
    } elseif ($k -eq 'G') {
        $top = $lines.Count - $pageSize
    } elseif ($k -eq 'H' -or $k -eq 'Home') {
        $top = 0
    }

    $top = [Math]::Max(0, [Math]::Min($top, [Math]::Max(0, $lines.Count - $pageSize)))
}
