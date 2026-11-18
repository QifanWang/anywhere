# shell env - bash / zsh（Unix / WSL / macOS / Linux）
# 用法: 在 ~/.bashrc（或 ~/.zshrc）末尾加一行：
#   . "$HOME/anywhere/config/shell/env.sh"
# ⚠️ 必须放在 . "$HOME/.cargo/env" 之后（若使用 rustup）：
#    cargo env 会把 ~/.cargo/bin prepend 到 PATH 第 1 位，导致 cargo 装的旧版工具
#    （如 ya 26.5.6）遮蔽 ~/.local/bin 里的新版（26.9.1）；本文件把 ~/.local/bin
#    重新前置修正。
# eza 别名在 ../eza/aliases.sh，单独 source。
# linux-fedora 实测：yazi 26.9.1 / glow v3.0.0 / helix 25.07.1 / fzf 0.75.0 / fd 10.2.0

# --- PATH 修正：让 ~/.local/bin 里的新版工具优先 ---
# 注意：不能只判断「PATH 里存在 .local/bin」就跳过 —— 它本来就存在，
# 但排在 ~/.cargo/bin 后面，旧版工具仍会抢先。必须判断是否为第一项。
case "$PATH" in
  "$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# --- yazi → shell：退出后自动 cd 到 yazi 所在目录 ---
# 不想改当前目录时按 Q 退出（quit --no-cwd-file）
y() {
  local tmp cwd
  tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
  yazi "$@" --cwd-file="$tmp"
  cwd="$(cat "$tmp")"
  rm -f -- "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd -- "$cwd"
  return 0
}

# --- yazi → glow：在 yazi 里 open 一个文件，退出后自动精读 ---
yg() {
  local tmp f
  tmp="$(mktemp -t 'yazi-chooser.XXXXXX')"
  yazi "$@" --chooser-file="$tmp"
  f="$(head -1 "$tmp")"
  rm -f -- "$tmp"
  [[ -f "$f" ]] && GLOW_WIDTH="$(tput cols)" glow "$f"
  return 0
}

# --- glow：按当前 pane 宽度渲染，绕开 v3 的 120 列上限 ---
gw() { GLOW_WIDTH="$(tput cols 2>/dev/null || echo 0)" glow "$@"; }

# --- fzf：yazi 内置 fzf 插件（z 键）与命令行 fzf 的默认候选源 ---
# 无管道输入时 fzf 用此命令列候选；fd 比 find 快、含隐藏文件、排除 .git
export FZF_DEFAULT_COMMAND='fd --type f --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
# 命令行直接敲 fzf、yazi z 键只用以上两个变量，无需 fzf 的 shell 集成脚本。

# --- helix：替代 nano 的模态编辑器（yazi o/e、git commit 均走 EDITOR） ---
# 二进制 ~/.local/bin/hx（软链到 ~/.cargo/bin/hx，linux-fedora 源码编译）
# runtime 从官方包解到 ~/.local/lib/helix/runtime（查询/主题/语法与二进制同版本）
export HELIX_RUNTIME="$HOME/.local/lib/helix/runtime"
export EDITOR="hx"
export VISUAL="hx"
