#!/usr/bin/env bash
# 3.1 前置准备：检查依赖并准备用户级安装目录（无需 root）。可重复运行。
# 缺失必需依赖时逐项列出并以非零码退出；tmux 由系统提供，缺失不影响其他工具。
set -euo pipefail

BIN="$HOME/.local/bin"
missing=0

check_cmd() {
  local cmd="$1" role="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '  [OK]   %-6s %s\n' "$cmd" "$role"
  else
    printf '  [MISS] %-6s %s\n' "$cmd" "$role"
    missing=$((missing + 1))
  fi
}

echo "==> 必需依赖"
check_cmd curl  "下载 Release 包（yazi / fd / fzf / lazygit）"
check_cmd unzip "解压 yazi musl 包"
check_cmd tar   "解压 fd / fzf / lazygit / helix runtime"
check_cmd cargo "eza / helix 编译（需 rustup stable）"

echo "==> Go（glow v3 要求 >= 1.26.5）"
raw="$(go version 2>/dev/null || true)"
if [[ "$raw" =~ go([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[4]:-0}"
  if (( major > 1 || (major == 1 && minor > 26) || (major == 1 && minor == 26 && patch >= 5) )); then
    printf '  [OK]   go%s.%s.%s\n' "$major" "$minor" "$patch"
  else
    printf '  [MISS] go%s.%s.%s（glow v3 要求 >= 1.26.5）\n' "$major" "$minor" "$patch"
    missing=$((missing + 1))
  fi
else
  printf '  [MISS] go 未安装或版本无法解析：%s\n' "${raw:-<无输出>}"
  missing=$((missing + 1))
fi

echo "==> 可选"
if command -v git >/dev/null 2>&1; then
  printf '  [OK]   git    %s\n' "$(git --version 2>/dev/null | head -1 || true)"
else
  echo '  [NOTE] git 未安装（仅 helix 手动源码编译需要）'
fi
if command -v tmux >/dev/null 2>&1; then
  printf '  [OK]   tmux %s\n' "$(tmux -V)"
else
  echo '  [NOTE] tmux 未安装（标准 Fedora 用 sudo dnf install tmux）'
fi

mkdir -p "$BIN"
echo "==> 用户级安装目录：$BIN"

if (( missing > 0 )); then
  printf '\n%d 项依赖缺失，请补齐后重跑本脚本。\n' "$missing"
  exit 1
fi
printf '\n前置准备完成。下一步：bash scripts/linux-fedora/install.sh\n'
