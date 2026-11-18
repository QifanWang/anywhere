#!/usr/bin/env bash
# ============================================================
# linux-fedora（RHEL 系）工具安装脚本
# 实测环境: TencentOS Server 3.3（ID_LIKE="rhel fedora centos"）/ glibc 2.28 / x86_64
#           dnf 不可用 → 全部用户级安装到 ~/.local/bin，无需 root
# 策略:   Rust 系（yazi/fd）用 GitHub Release musl 静态包规避老 glibc；
#         Go 系（fzf/lazygit）用官方 Release 单二进制；glow 用 go install（v3）；
#         eza 用 cargo install。
# 不含:   helix（源码编译 + grammar 补丁，见 docs/linux-fedora/INSTALL.md §6）
#         tmux（系统自带；标准 Fedora 用 dnf install tmux）
# 依赖:   curl / unzip / tar；eza 需 rustup（cargo）；glow 需 go >= 1.26.5
# 用法:   bash scripts/linux-fedora/install.sh
# 幂等:   已安装的工具跳过；升级时改下面的版本号后先删旧二进制
# ============================================================
set -euo pipefail

BIN="$HOME/.local/bin"
mkdir -p "$BIN"

# 实测锁定版本（升级时同步更新 docs/linux-fedora/INSTALL.md 的版本档案）
YAZI_VER="26.9.1"
FD_VER="10.2.0"
FZF_VER="0.75.0"
LAZYGIT_VER="0.66.3"

log()  { printf '\n==> %s\n' "$*"; }
skip() { printf '    [skip] %s\n' "$*"; }
need() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 \
      || { printf '[error] 缺少依赖: %s\n' "$c" >&2; exit 1; }
  done
}

install_yazi() {
  if command -v yazi >/dev/null 2>&1 && command -v ya >/dev/null 2>&1; then
    skip "yazi/ya 已安装: $(yazi --version)"; return
  fi
  need curl unzip
  log "安装 yazi/ya ${YAZI_VER}（musl 静态包）"
  curl -fL -o /tmp/yazi.zip \
    "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VER}/yazi-x86_64-unknown-linux-musl.zip"
  unzip -oq /tmp/yazi.zip -d /tmp/yazi-dist
  local d="/tmp/yazi-dist/yazi-x86_64-unknown-linux-musl"
  install -m 755 "$d/yazi" "$BIN/yazi"
  install -m 755 "$d/ya"   "$BIN/ya"
  rm -rf /tmp/yazi.zip /tmp/yazi-dist
  "$BIN/yazi" --version
}

install_fd() {
  if command -v fd >/dev/null 2>&1; then skip "fd 已安装: $(fd --version)"; return; fi
  need curl tar
  log "安装 fd ${FD_VER}（musl 静态包；yazi s 键 / gf 平铺视图依赖）"
  curl -fsSL -o /tmp/fd.tgz \
    "https://github.com/sharkdp/fd/releases/download/v${FD_VER}/fd-v${FD_VER}-x86_64-unknown-linux-musl.tar.gz"
  tar -xzf /tmp/fd.tgz -C /tmp
  install -m 755 "/tmp/fd-v${FD_VER}-x86_64-unknown-linux-musl/fd" "$BIN/fd"
  rm -rf /tmp/fd.tgz "/tmp/fd-v${FD_VER}-x86_64-unknown-linux-musl"
  "$BIN/fd" --version
}

install_fzf() {
  if command -v fzf >/dev/null 2>&1; then skip "fzf 已安装: $(fzf --version)"; return; fi
  need curl tar
  log "安装 fzf ${FZF_VER}（yazi z 键依赖）"
  # ⚠️ asset 文件名不带 v 前缀（tag 是 v0.75.0、文件是 fzf-0.75.0-…）
  curl -fsSL -o /tmp/fzf.tgz \
    "https://github.com/junegunn/fzf/releases/download/v${FZF_VER}/fzf-${FZF_VER}-linux_amd64.tar.gz"
  tar -xzf /tmp/fzf.tgz -C /tmp
  install -m 755 /tmp/fzf "$BIN/fzf"
  rm -f /tmp/fzf.tgz /tmp/fzf
  "$BIN/fzf" --version
}

install_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then skip "lazygit 已安装: $(lazygit --version)"; return; fi
  need curl tar
  log "安装 lazygit ${LAZYGIT_VER}（yazi gi 键依赖）"
  curl -fsSL -o /tmp/lazygit.tgz \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VER}/lazygit_${LAZYGIT_VER}_Linux_x86_64.tar.gz"
  tar -xzf /tmp/lazygit.tgz -C /tmp lazygit
  install -m 755 /tmp/lazygit "$BIN/lazygit"
  rm -f /tmp/lazygit.tgz /tmp/lazygit
  "$BIN/lazygit" --version
}

install_glow() {
  if command -v glow >/dev/null 2>&1; then skip "glow 已安装"; return; fi
  need go curl
  log "安装 glow v3（go install，要求 go >= 1.26.5）"
  # ⚠️ v3 模块路径是 charm.land/glow/v3，不是 github.com/charmbracelet/glow
  go install charm.land/glow/v3@latest
  ln -sf "$(go env GOPATH)/bin/glow" "$BIN/glow"
  "$BIN/glow" --version
}

install_eza() {
  if command -v eza >/dev/null 2>&1; then skip "eza 已安装: $(eza --version | head -1)"; return; fi
  need cargo curl
  log "安装 eza（cargo install，rustup stable）"
  cargo install eza
  ln -sf "$HOME/.cargo/bin/eza" "$BIN/eza"
  "$BIN/eza" --version
}

main() {
  log "linux-fedora 工具安装（目标: ${BIN}）"

  command -v tmux >/dev/null 2>&1 \
    && skip "tmux 已安装: $(tmux -V)" \
    || printf '    [note] tmux 未安装：标准 Fedora 用 sudo dnf install tmux\n'

  install_yazi
  install_fd
  install_fzf
  install_lazygit
  install_glow
  install_eza

  log "完成。helix 未自动安装（源码编译），见 docs/linux-fedora/INSTALL.md §6"
  printf '  接下来运行: bash scripts/shared/bootstrap.sh  链接配置\n'
  printf '  shell 集成（~/.bashrc 末尾，须在 .cargo/env 之后）:\n'
  printf '    . "$HOME/anywhere/config/shell/env.sh"\n'
  printf '    . "$HOME/anywhere/config/eza/aliases.sh"\n'
}

main "$@"
