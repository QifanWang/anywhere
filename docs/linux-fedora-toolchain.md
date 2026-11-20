# Linux（Fedora / RHEL 系）工具链

## 1. 前置说明

平台工具链文档：`docs/linux-fedora-toolchain.md`。跨平台工具/功能对照见 [toolchain.yaml](toolchain.yaml)，命令速查见 `cheatsheet/`。

**实测环境**（2026-11，版本与路径均在本机验证）：

| 项 | 值 |
| --- | --- |
| 系统 | TencentOS Server 3.3（`ID_LIKE="rhel fedora centos"`，RHEL 系），无 GUI，ssh 使用 |
| Shell | bash / zsh |
| 关键约束 | glibc 2.28（x86_64）、无 root、dnf 不可用 |
| 策略 | 全部用户级安装到 `~/.local/bin`；Rust 系用 musl 静态包，helix 源码编译 |

> 标准 Fedora 上 `dnf install tmux eza` 等可直接用；本文以实测的「无 root / 老 glibc」路径为准，glibc ≥ 2.34 的机器可优先用官方 gnu 包。

两份工具链文档（`win11-toolchain.md` 与 `linux-fedora-toolchain.md`）使用相同章节结构：

```text
1. 前置说明
2. 工具与功能
3. 安装、配置与验证
```

**包管理器**：dnf 不可用，所有工具都安装到用户目录 `~/.local/bin`。glibc 2.28 下的策略：

| 工具类型 | 策略 | 原因 |
| --- | --- | --- |
| Rust 系（yazi、fd） | GitHub Release **musl 静态包** | 官方 gnu 包要求 `GLIBC_2.29+`（yazi 实测要 2.39），musl 包 static-pie 无 glibc 依赖 |
| Go 系（glow、lazygit、fzf） | GitHub Release 单二进制 / `go install` | Go 静态编译，无 glibc 依赖 |
| eza | `cargo install`（rustup stable） | crates.io 版本够新，编译可用 |
| helix | **源码编译**（官方包同样 glibc 不兼容） | 见 §3.2 |
| tmux | 系统自带 | tmux 2.7 够用 |

**终端与 Shell**：

| 项 | 当前状态 |
| --- | --- |
| 终端 | ssh 客户端 + 终端模拟器；Nerd Font 由客户端配置，eza / yazi 图标依赖它 |
| Shell | bash / zsh |
| PATH | `config/shell/env.sh` 把 `~/.local/bin` **前置为第一项**（仅“存在”不够）；必须放在 `. "$HOME/.cargo/env"` 之后 |
| 历史命令 | **当前不配置** |
| 智能提示 | **当前不配置** |
| Wrapper / 环境变量 | `y` / `yg` / `gw`；`FZF_DEFAULT_COMMAND`、`FZF_DEFAULT_OPTS`、`HELIX_RUNTIME`、`EDITOR=hx`、`VISUAL=hx` |

`env.sh` 与 eza 别名的加载命令见 §3.2。

## 2. 工具与功能

本平台工具清单如下；每个工具承载的功能及跨平台对照见 [toolchain.yaml](toolchain.yaml)。

| 工具 | 承载功能 | 版本 | 二进制位置 | 配置源 |
| --- | --- | --- | --- | --- |
| tmux | 终端复用、会话保持 | 2.7 | `/usr/bin/tmux` | `../config/tmux/tmux.conf` |
| yazi / ya | 文件管理、预览 | 26.9.1 | `~/.local/bin/` | `../config/yazi/` |
| fd | 文件查找（yazi `s` / `gf`、fzf 候选源） | 10.2.0 | `~/.local/bin/fd` | — |
| fzf | 模糊搜索（yazi `z`） | 0.75.0 | `~/.local/bin/fzf` | `../config/shell/env.sh` |
| lazygit | Git 面板（yazi `gi`） | 0.66.3 | `~/.local/bin/lazygit` | — |
| glow | Markdown 阅读 / 预览 | 3.0.0 | `~/.local/bin/glow` → `$GOPATH/bin/glow` | `../config/glow/glow.yml` |
| eza | 目录列表 | 0.23.5 | `~/.local/bin/eza` → `~/.cargo/bin/eza` | `../config/eza/aliases.sh` |
| helix | 模态编辑器（`EDITOR`） | 25.07.1 | `~/.local/bin/hx` → `~/.cargo/bin/hx` | `../config/helix/config.toml` |

本地注意事项：

- yazi 的 `g f` / `g i` / `g v` 在 `keymap.toml` 中声明 `for = "unix"`，依赖 fd / lazygit；`z` 依赖 fzf 二进制。
- glow 非 TTY + 文件参数输出为空，预览插件需走 stdin；eza 非 TTY 自动关颜色，预览插件需 `--color=always`。
- helix 的 `HELIX_RUNTIME` 与 `EDITOR` / `VISUAL` 由 `config/shell/env.sh` 提供。

## 3. 安装、配置与验证

四步分别由 `scripts/linux-fedora/` 下的脚本完成，按顺序执行：

```bash
bash scripts/linux-fedora/prepare.sh     # 前置准备
bash scripts/linux-fedora/install.sh     # 安装工具链
bash scripts/linux-fedora/bootstrap.sh   # 链接配置
bash scripts/linux-fedora/verify.sh      # 验证（新开终端后）
```

> 除 helix 外，命令都收进脚本；下文只保留手动步骤、脚本背后的关键点和排错信息。

### 3.1 前置准备

`prepare.sh` 检查必需依赖（`curl` / `unzip` / `tar` / `cargo`、Go ≥ 1.26.5）并创建用户级安装目录 `~/.local/bin`，无需 root。缺失项逐条列出并以非零码退出，补齐后重跑即可。tmux 由系统提供（标准 Fedora 用 `dnf install tmux`），git 仅供 helix 手动编译，两者缺失都不影响脚本安装其他工具。

### 3.2 工具链

**安装**

`install.sh` 安装 §2 中除 helix 外的全部命令行工具，幂等：已安装的会跳过；升级时改脚本顶部版本号并先删旧二进制。

手动安装仅 helix 例外（官方包要求 `GLIBC_2.29+`，glibc 2.28 只能源码编译；耗时约十几分钟，`install.sh` 不自动执行）：

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

脚本背后的关键点（排错时参考）：

- 不要用 `cargo install yazi-fm`：crates.io 只到 26.5.6，asset 宏写死 monorepo 兄弟目录布局，从 registry 安装必失败（26 个 `include_bytes!` 报错）；国内镜像还会绕过 build.rs 防护。脚本用 GitHub Release 的 musl 静态包。
- glow v3 的模块路径是 `charm.land/glow/v3`，不是 `github.com/charmbracelet/glow`（后者 `go install` 会装到 v1.5.1）。
- fzf asset 文件名不带 v 前缀（tag `v0.75.0`、文件 `fzf-0.75.0-…`）。
- `go install` 的 `$GOPATH/bin` 与 cargo 的 `~/.cargo/bin` 不在 PATH 时，脚本会软链到 `~/.local/bin`；fzf 候选源与外观由 `config/shell/env.sh` 的 `FZF_DEFAULT_COMMAND` / `FZF_DEFAULT_OPTS` 提供，无需 fzf shell 集成脚本。

**配置链接**

`bootstrap.sh` 把 `../config/glow/`、`../config/yazi/`、`../config/helix/` 链接到 `~/.config/`；tmux ≥ 3.1 链接 `../config/tmux/` → `~/.config/tmux/`，tmux < 3.1（含 2.7）改链单文件 `~/.tmux.conf`。已有配置先备份为 `.bak`，已指向同一源目录的链接会跳过。

shell 集成（只需一次）：在 `~/.bashrc`（或 `~/.zshrc`）**末尾**追加：

```bash
. "$HOME/anywhere/config/shell/env.sh"
. "$HOME/anywhere/config/eza/aliases.sh"
```

> ⚠️ 必须放在 `. "$HOME/.cargo/env"` **之后**（若使用 rustup）：cargo env 会把 `~/.cargo/bin` prepend 到 PATH 第 1 位，本文件把 `~/.local/bin` 重新前置，否则 cargo 装的旧版 `ya` 等会遮蔽新版。

yazi 插件（已随仓库入库）：`git.yazi` / `vcs-files.yazi` 在 `../config/yazi/plugins/`，`bootstrap.sh` 整目录链接后即生效，无需联网。若改用 `ya pkg add yazi-rs/plugins:git` / `yazi-rs/plugins:vcs-files`：语法是 `repo:name`（冒号），fzf 插件已内置化（add 失败属正常），且 `~/.config/yazi` 是指向本仓库的软链时会直接写进仓库。

git 角标三件套缺一不可：`yazi.toml` 的 `prepend_fetchers` + `init.lua` 的 `require("git"):setup` + `theme.toml` `[git]` 段配色。

**验证**

新开终端后运行 `verify.sh`：非交互式检查命令与版本、PATH 首项与解析路径、配置链接、shell 集成、yazi 插件；逐项 PASS / FAIL，有失败项时退出码为 1。

脚本不覆盖的交互项：

- yazi：`gf` 平铺视图 / `gi` lazygit / `gv` 变更文件 / `z` 模糊搜索；`.md` 文件预览应为 glow 渲染。
- glow 非 TTY + 文件参数必须走 stdin、eza 非 TTY 需 `--color=always`（预览插件已处理，见排错表）。

**排错**

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
