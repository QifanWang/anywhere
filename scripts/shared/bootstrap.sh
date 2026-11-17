#!/usr/bin/env bash
# 把仓库中的配置链接到 XDG 配置目录（WSL / macOS / Linux）
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

mkdir -p "$CONFIG_HOME"

link_dir() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    rm -f "$dst"
  elif [ -e "$dst" ]; then
    local backup="${dst}.bak"
    rm -rf "$backup"
    mv "$dst" "$backup"
    echo "[backup] $backup"
  fi

  ln -s "$src" "$dst"
  echo "[link]   $dst -> $src"
}

echo "==> Repository: $REPO"
link_dir "$REPO/config/tmux" "$CONFIG_HOME/tmux"
link_dir "$REPO/config/glow" "$CONFIG_HOME/glow"
link_dir "$REPO/config/yazi" "$CONFIG_HOME/yazi"

echo
echo "==> 接下来（只需一次）"
echo "  在 ~/.bashrc 或 ~/.zshrc 中加入："
echo "    . \"$REPO/config/eza/aliases.sh\""
echo
echo "完成。"
