# Fedora / RHEL 系安装指南（linux-fedora）

平台专属文档，位于 `docs/linux-fedora/`。通用命令速查见 `../CHEATSHEET.md`。

**实测环境**（2026-11，版本与路径均在本机验证）：

| 项 | 值 |
| --- | --- |
| 发行版 | TencentOS Server 3.3（`ID_LIKE="rhel fedora centos"`，RHEL 系） |
| glibc | 2.28（x86_64） |
| 包管理器 | dnf 不可用（权限错误），**全部走用户级安装**（`~/.local/bin`） |
| 图形界面 | 无（服务器，ssh 使用） |
| tmux | 2.7（系统自带 `/usr/bin/tmux`） |

> 标准 Fedora 上 `dnf install tmux eza` 等可直接用；本指南以实测的「无 root / 老 glibc」路径为准，glibc ≥ 2.34 的机器可优先用官方 gnu 包。

## 1. glibc 2.28 安装策略（核心）

| 工具类型 | 策略 | 原因 |
| --- | --- | --- |
| Rust 系（yazi、fd） | GitHub Release **musl 静态包** | 官方 gnu 包要求 `GLIBC_2.29+`（yazi 实测要 2.39），musl 包 static-pie 无 glibc 依赖 |
| Go 系（glow、lazygit、fzf） | GitHub Release 单二进制 / `go install` | Go 静态编译，无 glibc 依赖 |
| eza | `cargo install`（rustup stable） | crates.io 版本够新，编译可用 |
| helix | **源码编译**（官方包同样 glibc 不兼容） | 见 §6 |
| tmux | 系统自带 | tmux 2.7 够用 |

## 2. 版本 / 路径档案（实测锁定）

| 工具 | 版本 | 二进制位置 | 安装方式 |
| --- | --- | --- | --- |
| `tmux` | 2.7 | `/usr/bin/tmux` | 系统自带 |
| `yazi` / `ya` | 26.9.1 | `~/.local/bin/` | Release musl 包 |
| `fd` | 10.2.0 | `~/.local/bin/fd` | Release musl 包（yazi `s` 键 / `gf` 平铺视图依赖） |
| `fzf` | 0.75.0 | `~/.local/bin/fzf` | Release 单二进制（yazi `z` 键依赖） |
| `lazygit` | 0.66.3 | `~/.local/bin/lazygit` | Release 单二进制（yazi `gi` 键依赖） |
| `glow` | v3.0.0 | `~/.local/bin/glow` → `$GOPATH/bin/glow` | `go install` |
| `eza` | 0.23.5 | `~/.local/bin/eza` → `~/.cargo/bin/eza` | `cargo install` |
| `helix` | 25.07.1 | `~/.local/bin/hx` → `~/.cargo/bin/hx` | 源码编译 |

一键安装（helix 除外，见 §6）：

```bash
bash scripts/linux-fedora/install.sh
```

## 3. yazi / ya（musl 静态包）

```bash
curl -fL -o /tmp/yazi.zip \
  https://github.com/sxyazi/yazi/releases/download/v26.9.1/yazi-x86_64-unknown-linux-musl.zip
unzip -o /tmp/yazi.zip -d /tmp/yazi-dist
d=/tmp/yazi-dist/yazi-x86_64-unknown-linux-musl
install -m 755 "$d/yazi" "$HOME/.local/bin/yazi"
install -m 755 "$d/ya"   "$HOME/.local/bin/ya"
yazi --version && ya --version
rm -rf /tmp/yazi.zip /tmp/yazi-dist
```

**不要用 `cargo install yazi-fm`**：crates.io 上只到 26.5.6，且其 asset 宏按 monorepo 兄弟目录布局写死相对路径，从 registry 安装必失败（26 个 `include_bytes!` 报错）；官方 build.rs 的防护只认 `index.crates.io-` 路径，国内镜像（如腾讯镜像）会绕过防护静默跳过。

## 4. fd / fzf / lazygit（Release 静态包）

```bash
# fd —— yazi 的 s 键与 gf 平铺视图依赖
curl -fsSL -o /tmp/fd.tgz \
  https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-musl.tar.gz
tar -xzf /tmp/fd.tgz -C /tmp
install -m 755 /tmp/fd-v10.2.0-x86_64-unknown-linux-musl/fd ~/.local/bin/fd

# fzf —— yazi 26.9.1 默认键位已把 z 绑到内置 fzf 插件，装上二进制即生效
# ⚠️ asset 文件名不带 v 前缀（tag 是 v0.75.0、文件是 fzf-0.75.0-…），拼错 404
curl -fsSL -o /tmp/fzf.tgz \
  https://github.com/junegunn/fzf/releases/download/v0.75.0/fzf-0.75.0-linux_amd64.tar.gz
tar -xzf /tmp/fzf.tgz -C /tmp
install -m 755 /tmp/fzf ~/.local/bin/fzf

# lazygit —— yazi 的 gi 键 shell --block 拉起
curl -fsSL -o /tmp/lazygit.tgz \
  https://github.com/jesseduffield/lazygit/releases/download/v0.66.3/lazygit_0.66.3_Linux_x86_64.tar.gz
tar -xzf /tmp/lazygit.tgz -C /tmp lazygit
install -m 755 /tmp/lazygit ~/.local/bin/lazygit
```

fzf 的候选源与外观由 `FZF_DEFAULT_COMMAND` / `FZF_DEFAULT_OPTS` 控制，已设在 `config/shell/env.sh`（fd 候选源，含隐藏文件、排除 `.git`），无需 fzf 的 shell 集成脚本。

## 5. glow（v3）与 eza

glow v3 的 Go 模块路径**不是** `github.com/charmbracelet/glow`：

| 命令 | 结果 |
| --- | --- |
| `go install github.com/charmbracelet/glow@latest` | 装到的是 v1.5.1（2023 年，坑） |
| `go install github.com/charmbracelet/glow/v2@latest` | v2.1.2 |
| `go install github.com/charmbracelet/glow/v3@latest` | **失败**：module declares its path as `charm.land/glow/v3` |
| `go install charm.land/glow/v3@latest` | **v3.0.0**（要求 Go ≥ 1.26.5） |

```bash
go install charm.land/glow/v3@latest
ln -sf "$(go env GOPATH)/bin/glow" "$HOME/.local/bin/glow"
```

> `go install` 的 `$GOPATH/bin` 不在 PATH 里，会表现为「装完找不到命令」——软链到 `~/.local/bin` 即可。

eza：

```bash
cargo install eza            # rustup stable，实测 v0.23.5
ln -sf "$HOME/.cargo/bin/eza" "$HOME/.local/bin/eza"
```

## 6. helix（源码编译；glibc 2.28 回退路径）

官方包 `helix-25.07.1-x86_64-linux.tar.xz` 要求 `GLIBC_2.29+`，老系统只能源码编译。**耗时最长（约十几分钟），`install.sh` 不自动执行**：

```bash
# 1) 源码 + grammar 子模块
git clone --recurse-submodules --depth 1 --branch 25.07.1 \
  https://github.com/helix-editor/helix /tmp/helix-src

# 2) grammar 补丁（两个子模块源不可达，见下）
cd /tmp/helix-src
# gotmpl: 原仓库 dannylongeuay/tree-sitter-go-template 已从 GitHub 删除（404），
#         按官方主分支换成 ngalaiko/tree-sitter-go-template（rev aa71f63 开头）
# prolog: grammar 源在 codeberg.org（本网络不可达），从 languages.toml 删掉其
#         [[grammar]] 条目（[[language]] 保留，代价仅 prolog 文件无语法高亮）
# —— 补丁是 TOML 手工编辑，无可靠 sed 脚本，见下方「编译踩坑」

# 3) 用 rustup stable 编译（repo 的 rust-toolchain.toml 锁 1.82，会因依赖
#    edition2024 失败；RUSTUP_TOOLCHAIN 强制覆盖，--locked 用仓库 Cargo.lock）
RUSTUP_TOOLCHAIN=stable cargo install --path helix-term --locked

# 4) 软链（同 eza 约定；~/.cargo/bin 非交互 shell 不可见）
ln -sf ~/.cargo/bin/hx ~/.local/bin/hx

# 5) runtime（查询/主题/语法高亮，与二进制同版本，平台无关）从官方包提取
curl -fsSL -o /tmp/helix.tar.xz \
  https://github.com/helix-editor/helix/releases/download/25.07.1/helix-25.07.1-x86_64-linux.tar.xz
mkdir -p ~/.local/lib/helix
tar -xJf /tmp/helix.tar.xz -C /tmp
cp -r /tmp/helix-25.07.1-x86_64-linux/runtime ~/.local/lib/helix/
```

编译踩坑（实测）：

1. 非 `bash -ic` 环境无 `~/.cargo/bin`，后台脚本要显式 export PATH
2. `rust-toolchain.toml` 锁 1.82.0 → cargo 1.82 无 edition2024；不带 `--locked` 重新解析依赖必失败
3. grammar 拉取 245 个中 2 个失败（gottmp 404 / prolog 不可达）；补丁后重跑 `cargo install`，已编译 crate 直接复用

`HELIX_RUNTIME` / `EDITOR=hx` / `VISUAL=hx` 已设在 `config/shell/env.sh`。

## 7. yazi 插件（已随仓库入库）

`git.yazi`（列表 git 角标）与 `vcs-files.yazi`（`gv` 键变更文件视图）已复制到 `config/yazi/plugins/`，`bootstrap.sh` 整目录链接后即生效，**无需联网安装**。

如需改用包管理器方式（更新更及时，但版本不锁定）：

```bash
ya pkg add yazi-rs/plugins:git
ya pkg add yazi-rs/plugins:vcs-files
```

> ⚠️ 语法是 `repo:name`（**冒号**），写成 `repo#name` 报 "must be in kebab-case"。
> ⚠️ `yazi-rs/plugins:fzf` 会失败——fzf 插件已内置化并从插件仓库移除，属正常。
> ⚠️ 若 `~/.config/yazi` 是指向本仓库的软链，`ya pkg add` 会直接写进仓库（`git status` 变脏）。

git 角标三件套缺一不可：`yazi.toml` 的 `prepend_fetchers` + `init.lua` 的 `require("git"):setup` + `theme.toml` `[git]` 段配色。

## 8. 链接配置与 shell 集成

```bash
bash scripts/shared/bootstrap.sh
```

脚本会：

- 把 `config/glow`、`config/yazi`、`config/helix` 链接到 `~/.config/`
- **tmux 版本分支**：tmux ≥ 3.1 链接 `config/tmux` → `~/.config/tmux`；**tmux < 3.1（含 2.7）不认 XDG 路径**，改为链接单文件 `~/.tmux.conf`

然后在 `~/.bashrc`（或 `~/.zshrc`）**末尾**追加：

```bash
. "$HOME/anywhere/config/shell/env.sh"
. "$HOME/anywhere/config/eza/aliases.sh"
```

> ⚠️ 必须放在 `. "$HOME/.cargo/env"` **之后**（若使用 rustup）：cargo env 会把 `~/.cargo/bin` prepend 到 PATH 第 1 位，本文件把 `~/.local/bin` 重新前置，否则 cargo 装的旧版 `ya` 等会遮蔽 `~/.local/bin` 里的新版。

## 9. 验证安装

```bash
tmux -V; yazi --version; ya --version; glow --version; eza --version
fd --version; fzf --version; lazygit --version; hx --version

# 解析路径（确认全部命中 ~/.local/bin）
bash -ic 'for b in yazi ya glow eza fd fzf lazygit hx; do printf "%-9s %s\n" "$b" "$(command -v "$b")"; done'

# yazi：gf 平铺视图 / gi lazygit / gv 变更文件 / z 模糊搜索；.md 文件预览应为 glow 渲染
```

## 10. 踩坑速查（浓缩版）

| # | 坑 | 要点 |
| --- | --- | --- |
| 1 | yazi gnu 包 `GLIBC_2.39 not found` | glibc 2.28 必须用 musl 静态包（fd 同理） |
| 2 | `cargo install yazi-fm` 必失败 | asset 宏写死 monorepo 路径；镜像绕过 build.rs 防护 |
| 3 | glow v3 模块路径 | `charm.land/glow/v3`，不是 `github.com/charmbracelet/glow/v3` |
| 4 | glow `-w 0` 输出为空 | v3 上 0 会直接传给 glamour 导致空输出；自适应只在配置文件 `width: 0` 生效，且有 120 列硬上限（突破用 `GLOW_WIDTH`） |
| 5 | glow OSC 8 超链接 | 以 BEL（`\a`）结尾，yazi ANSI 解析不认识（预览折行处 `^G`）、less < 590 会拆坏；yazi 插件与 opener 用 sed 剥除 |
| 6 | glow 非 TTY + 文件参数输出为空 | 预览插件必须 `glow - < 'file'` 从 stdin 读 |
| 7 | eza 非 TTY 自动关颜色 | 预览插件必须 `--color=always` |
| 8 | yazi 目录 mime 是 `folder/*` | 不是 `inode/directory`（26.9.1 实测） |
| 9 | `.md` 的 mime 是 `text/plain` | open / previewer 规则必须加 `url = "*.md"` 兜底 |
| 10 | 插件里 `job.file.path` 是 userdata | 传给 `Command:arg()` 前必须 `tostring()` |
| 11 | tmux 2.7 不认 `~/.config/tmux/` | XDG 支持是 3.1+，配置须放 `~/.tmux.conf` |
| 12 | tmux `mode-keys emacs` | copy-mode 搜索是 `C-s` / `C-r`，不是 vi 的 `/` |
| 13 | PATH 前置判断 | 只判断「存在 `.local/bin`」会失效（它存在但不在首位），必须判断「是否第一项」 |
| 14 | fzf asset 命名 | tag `v0.75.0`、文件 `fzf-0.75.0-…`，不带 v 前缀 |
| 15 | `ya pkg add` 语法 | `repo:name` 冒号分隔；fzf 插件已内置化，add 会失败属正常 |
