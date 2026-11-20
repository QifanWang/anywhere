#!/usr/bin/env bash
# 3.2 验证：非交互式检查命令、版本、PATH、配置链接与 shell 集成。
# 交互项（yazi 键位、glow 渲染等）见 docs/linux-fedora-toolchain.md。
set -uo pipefail

BIN="$HOME/.local/bin"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
failed=0

pass() { printf '  [PASS] %s%s\n' "$1" "${2:+ - $2}"; }
fail() { printf '  [FAIL] %s%s\n' "$1" "${2:+ - $2}"; failed=$((failed + 1)); }

echo "==> 命令与版本"
for spec in "yazi:--version" "ya:--version" "glow:--version" "eza:--version" \
            "fd:--version" "fzf:--version" "lazygit:--version" "hx:--version" "tmux:-V"; do
  cmd="${spec%%:*}"
  arg="${spec#*:}"
  if command -v "$cmd" >/dev/null 2>&1; then
    ver="$("$cmd" "$arg" 2>/dev/null | head -1 || true)"
    pass "$cmd" "${ver:-$(command -v "$cmd")}"
  else
    fail "$cmd" "不在 PATH（重开终端或检查 $BIN）"
  fi
done

echo
echo "==> PATH 优先级"
first="${PATH%%:*}"
if [ "$first" = "$BIN" ]; then
  pass "PATH 首项" "$first"
else
  fail "PATH 首项" "实际为 $first，应为 $BIN（须在 .cargo/env 之后 source env.sh）"
fi
for b in yazi ya glow eza fd fzf lazygit hx; do
  if command -v "$b" >/dev/null 2>&1; then
    resolved="$(command -v "$b")"
    if [ "$resolved" != "$BIN/$b" ]; then
      fail "$b 解析路径" "$resolved（应为 $BIN/$b）"
    fi
  fi
done

echo
echo "==> 配置链接"
for name in glow yazi helix; do
  p="$CONFIG_HOME/$name"
  if [ -e "$p" ]; then pass "config/$name" "$p"; else fail "config/$name" "缺失: $p"; fi
done
if command -v tmux >/dev/null 2>&1; then
  tmux_major="$(tmux -V 2>/dev/null | awk '{print $2}' | cut -d. -f1)"
  if [ "${tmux_major:-0}" -ge 3 ]; then p="$CONFIG_HOME/tmux"; else p="$HOME/.tmux.conf"; fi
  if [ -e "$p" ]; then pass "config/tmux" "$p"; else fail "config/tmux" "缺失: $p"; fi
else
  echo "  [SKIP] config/tmux - 未安装 tmux"
fi

echo
echo "==> shell 集成"
rc_found=0
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$rc" ] || continue
  if grep -Fq 'config/shell/env.sh' "$rc"; then pass "env.sh 引用" "$rc"; rc_found=1; fi
  if grep -Fq 'config/eza/aliases.sh' "$rc"; then pass "aliases.sh 引用" "$rc"; rc_found=1; fi
done
if (( rc_found == 0 )); then
  fail "shell 集成" "未在 ~/.bashrc / ~/.zshrc 找到 env.sh / aliases.sh 加载行"
fi

echo
echo "==> yazi 插件"
if [ -e "$CONFIG_HOME/yazi" ]; then
  for plug in git.yazi vcs-files.yazi; do
    p="$CONFIG_HOME/yazi/plugins/$plug"
    if [ -e "$p" ]; then pass "$plug" "$p"; else fail "$plug" "缺失: $p"; fi
  done
else
  echo "  [SKIP] yazi 配置缺失，跳过插件检查"
fi

echo
if (( failed > 0 )); then
  printf '%d 项未通过，详见 docs/linux-fedora-toolchain.md 排错。\n' "$failed"
  exit 1
fi
echo "全部通过。"
