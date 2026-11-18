# eza aliases - bash / zsh / Git Bash（Unix / WSL / macOS / Linux）
# Windows PowerShell 用同目录的 aliases.ps1
# 用法: . "$HOME/anywhere/config/eza/aliases.sh"
#
# 下半部分 ll / lt / lg 三个别名以 linux-fedora 实测参数为准（不带 --icons：
# ssh 服务器场景本地终端通常无 Nerd Font，图标会显示豆腐块）。
# 终端有 Nerd Font 时可自行加回 --icons。

command -v eza >/dev/null 2>&1 || return 0 2>/dev/null || true

alias ls='eza --color=always --icons --group-directories-first'
alias l='eza --color=always --icons --group-directories-first'
alias la='eza -a --color=always --icons --group-directories-first'
alias ltree='eza --tree --color=always --icons --group-directories-first'
alias lss='eza -l --color=always --icons --time-style=long-iso'

# --- linux-fedora 实测版（无 Nerd Font 环境调优）---
alias ll='eza -la --git --header'
alias lt='eza --tree --level=2 --git-ignore'
alias lg='eza -la --git --header --sort=modified'
