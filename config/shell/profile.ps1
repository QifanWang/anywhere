# anywhere / PowerShell 7 shell 交互配置
# 位置：$env:XDG_CONFIG_HOME\shell\profile.ps1（由 scripts/win11/bootstrap.ps1 链接）
# 用法：在 $PROFILE 末尾加一行：
#   . "$env:XDG_CONFIG_HOME\shell\profile.ps1"
# 加载顺序：eza 别名 -> PSReadLine -> zoxide -> oh-my-posh
# 每项都做存在性检查，缺任一工具都不会让 shell 启动失败。
# 对应 Unix 的 env.sh（bash / zsh）。

if ($env:XDG_CONFIG_HOME) {
    $anywhereCfg = $env:XDG_CONFIG_HOME
} else {
    $anywhereCfg = Join-Path $HOME ".config"
}

# --- eza 别名（沿用 config/eza/aliases.ps1，避免两处维护） ---
$ezaAliases = Join-Path $anywhereCfg "eza\aliases.ps1"
if (Test-Path -LiteralPath $ezaAliases) {
    . $ezaAliases
}

# --- PSReadLine：历史前缀搜索 + 菜单补全 + 基于历史的预测 ---
# PowerShell 7 内置模块；Set-PSReadLineOption 的预测选项需 >= 2.1，
# 2.2.6+ 默认开启。低版本用 try/catch 兜底，不影响其余初始化。
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine

    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete

    try {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle InlineView
    } catch {
        Write-Verbose "PSReadLine 预测不可用（版本偏低）: $($_.Exception.Message)"
    }
}

# --- zoxide：接管 cd，提供 z / zi 目录跳转 ---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# --- oh-my-posh：提示符（最后初始化，输出 prompt 脚本） ---
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompTheme = Join-Path $anywhereCfg "oh-my-posh\anywhere.omp.json"
    if (Test-Path -LiteralPath $ompTheme) {
        oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
    }
}
