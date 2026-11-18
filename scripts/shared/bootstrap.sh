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

# 单文件链接（备份逻辑同上）
link_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    rm -f "$dst"
  elif [ -e "$dst" ]; then
    local backup="${dst}.bak"
    rm -f "$backup"
    mv "$dst" "$backup"
    echo "[backup] $backup"
  fi

  ln -s "$src" "$dst"
  echo "[link]   $dst -> $src"
}

echo "==> Repository: $REPO"
link_dir "$REPO/config/glow" "$CONFIG_HOME/glow"
link_dir "$REPO/config/yazi" "$CONFIG_HOME/yazi"
link_dir "$REPO/config/helix" "$CONFIG_HOME/helix"

# tmux：3.1+ 支持 XDG 路径 ~/.config/tmux/tmux.conf；老版本（含 2.7）
# 只认 ~/.tmux.conf，改为单文件链接（实测 tmux 2.7 / TencentOS，见 docs/linux-fedora/INSTALL.md）
if command -v tmux >/dev/null 2>&1; then
  tmux_major="$(tmux -V 2>/dev/null | awk '{print $2}' | cut -d. -f1)"
  if [ "${tmux_major:-0}" -ge 3 ]; then
    link_dir "$REPO/config/tmux" "$CONFIG_HOME/tmux"
  else
    link_file "$REPO/config/tmux/tmux.conf" "$HOME/.tmux.conf"
    echo "[note]   tmux ${tmux_major}.x < 3.1，已链接到 ~/.tmux.conf（不支持 XDG 路径）"
  fi
else
  echo "[note]   未检测到 tmux，跳过（win11 用 config/rmux/rmux.conf）"
fi

echo
echo "==> 接下来（只需一次）"
echo "  在 ~/.bashrc 或 ~/.zshrc 末尾加入（须在 . \"\$HOME/.cargo/env\" 之后）："
echo "    . \"$REPO/config/shell/env.sh\""
echo "    . \"$REPO/config/eza/aliases.sh\""
echo
echo "  工具安装（linux-fedora）：bash scripts/linux-fedora/install.sh"
echo
echo "完成。"
