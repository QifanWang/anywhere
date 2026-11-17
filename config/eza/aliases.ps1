# eza aliases - PowerShell 5.1+ / 7+（Windows）
# 其他 shell 用同目录的 aliases.sh
# 用法: . "$HOME\anywhere\config\eza\aliases.ps1"

if (-not (Get-Command eza -ErrorAction SilentlyContinue)) {
    Write-Warning "eza not found; aliases were not loaded."
    return
}

function Invoke-EzaList {
    eza --color=always --icons --group-directories-first @args
}
function Invoke-EzaLong {
    eza -lah --color=always --icons --group-directories-first --git @args
}
function Invoke-EzaAll {
    eza -a --color=always --icons --group-directories-first @args
}
function Invoke-EzaTree {
    eza --tree --level=2 --color=always --icons @args
}
function Invoke-EzaFullTree {
    eza --tree --color=always --icons --group-directories-first @args
}
function Invoke-EzaGit {
    eza -lah --color=always --icons --group-directories-first --git @args
}
function Invoke-EzaISO {
    eza -l --color=always --icons --time-style=long-iso @args
}

Set-Alias -Name l     -Value Invoke-EzaList     -Force
Set-Alias -Name ll    -Value Invoke-EzaLong     -Force
Set-Alias -Name la    -Value Invoke-EzaAll      -Force
Set-Alias -Name lt    -Value Invoke-EzaTree     -Force
Set-Alias -Name ltree -Value Invoke-EzaFullTree -Force
Set-Alias -Name lg    -Value Invoke-EzaGit      -Force
Set-Alias -Name lss   -Value Invoke-EzaISO      -Force

# 如需完全替换内置 ls，取消下一行注释：
# Set-Alias -Name ls -Value Invoke-EzaList -Force
