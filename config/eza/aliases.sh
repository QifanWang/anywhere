# eza aliases - bash / zsh / Git Bash（Unix / WSL / macOS / Linux）
# Windows PowerShell 用同目录的 aliases.ps1
# 用法: . "$HOME/anywhere/config/eza/aliases.sh"

command -v eza >/dev/null 2>&1 || return 0 2>/dev/null || true

alias ls='eza --color=always --icons --group-directories-first'
alias l='eza --color=always --icons --group-directories-first'
alias ll='eza -lah --color=always --icons --group-directories-first --git'
alias la='eza -a --color=always --icons --group-directories-first'
alias lt='eza --tree --level=2 --color=always --icons'
alias ltree='eza --tree --color=always --icons --group-directories-first'
alias lg='eza -lah --color=always --icons --group-directories-first --git'
alias lss='eza -l --color=always --icons --time-style=long-iso'
