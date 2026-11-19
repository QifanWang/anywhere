# anywhere

跨平台现代 TUI 工具的**私人配置集合**。仓库中只保存「配置源文件」，由引导脚本把它们链接/复制到各平台的实际配置目录。

## 目录约定

- `docs/` 按主题组织：平台安装指南放 `win11/`、`linux-fedora/`，按工具拆分的速查表放 `cheatsheet/`。`scripts/` 按平台分层：`shared/` 放通用脚本，`win11/`、`linux-fedora/` 放平台专属脚本。
- `config/` **不按平台分层**，只按工具命名：`config/tmux/`、`config/rmux/`、`config/eza/` 等。`config/shell/` 放 shell 级的环境变量与 wrapper 函数。
- 工具配置尽量共用同一份文件；确实无法共用时，把变体放在同一工具目录内，并在文件头部写清适用平台。例如 `eza/aliases.sh`（bash/zsh）与 `eza/aliases.ps1`（PowerShell）、`tmux/tmux.conf`（非 win11）与 `rmux/rmux.conf`（win11）；yazi 的平台差异写在条目的 `for` 字段里。

| 工具 | 用途 | 配置源文件 | 适用平台 |
| --- | --- | --- | --- |
| [RMUX](https://github.com/Helvesec/rmux) | 终端复用、会话保持 | `config/rmux/rmux.conf` | win11 |
| [tmux](https://github.com/tmux/tmux) | 终端复用、会话保持 | `config/tmux/tmux.conf` | macOS / Linux / WSL |
| [eza](https://github.com/eza-community/eza) | 现代 `ls` 替代品 | `config/eza/aliases.sh`、`config/eza/aliases.ps1` | 全平台（按 shell 选文件） |
| [glow](https://github.com/charmbracelet/glow) | 终端 Markdown 阅读器 | `config/glow/glow.yml` | 全平台 |
| [yazi](https://github.com/sxyazi/yazi) | 终端文件管理器 | `config/yazi/{yazi,keymap,theme}.toml`、`config/yazi/init.lua`、`config/yazi/plugins/` | 全平台 |
| [helix](https://github.com/helix-editor/helix) | 模态编辑器（yazi / git 的 `EDITOR`） | `config/helix/config.toml` | linux-fedora 实测；win11 只链接配置 |
| shell 环境 | PATH 修正、`y`/`yg`/`gw` wrapper、fzf / helix 环境变量 | `config/shell/env.sh` | bash / zsh（Unix） |
| [fd](https://github.com/sharkdp/fd) | 文件查找（yazi `s` 键 / `gf` / fzf 候选源依赖，无配置文件） | — | linux-fedora；win11 未安装 |
| [fzf](https://github.com/junegunn/fzf) | 模糊搜索（yazi `z` 键，环境变量在 `config/shell/env.sh`） | — | linux-fedora；win11 需自行补装 |
| [lazygit](https://github.com/jesseduffield/lazygit) | git 面板（yazi `gi` 键拉起，无配置文件） | — | linux-fedora；win11 未安装 |

> `config/yazi/plugins/` 含 4 个插件：`glow.yazi` / `eza.yazi` 为自研预览插件（markdown→glow 渲染、目录→eza 树状），`git.yazi` / `vcs-files.yazi` 为官方插件（已入库锁定版本，恢复时无需联网 `ya pkg add`）。

## 目录结构

```
anywhere/
├── README.md
├── docs/
│   ├── toolchain.yaml             # win11 / linux-fedora 工具链对照（唯一数据源）
│   ├── cheatsheet/                # 按工具拆分的命令速查
│   │   ├── README.md
│   │   ├── rmux.md / tmux.md
│   │   ├── eza.md / glow.md
│   │   └── yazi.md / helix.md
│   ├── win11/
│   ├── win11-toolchain.md         # Windows 11 工具链指南
│   └── linux-fedora/
│   └── linux-fedora-toolchain.md  # Fedora / RHEL 系工具链指南（TencentOS 实测）
├── config/                        # 只按工具分目录，无平台子目录
│   ├── rmux/rmux.conf
│   ├── tmux/tmux.conf
│   ├── eza/{aliases.sh,aliases.ps1}
│   ├── glow/glow.yml
│   ├── helix/config.toml
│   ├── shell/env.sh               # PATH / wrapper / fzf / helix 环境变量
│   └── yazi/
│       ├── {yazi,keymap,theme}.toml
│       ├── init.lua               # git.yazi 角标 setup
│       └── plugins/               # glow / eza / git / vcs-files 四插件
└── scripts/
    ├── shared/bootstrap.sh        # XDG 链接（mac / linux-fedora 复用）
    ├── win11/
    │   ├── install.ps1            # 安装 rmux / eza / glow / yazi
    │   └── bootstrap.ps1          # 链接配置 + 校验/修复 PATH
    ├── mac/                       # 预留：macOS 安装脚本
    └── linux-fedora/
        └── install.sh             # 安装 yazi / fd / fzf / lazygit / glow / eza
```

`scripts/mac/` 只是预留目录，暂无安装脚本；macOS 文档占位已移除。

## 快速开始

**Windows 11（PowerShell）**

```powershell
.\scripts\win11\install.ps1       # 安装 rmux / eza / glow / yazi
.\scripts\win11\bootstrap.ps1     # 链接配置到 XDG/APPDATA，并校验/修复工具 PATH
```

然后在 PowerShell 配置文件中加载 eza 别名（见 `docs/win11-toolchain.md` 第 4.2 节）。命令速查见 `docs/cheatsheet/`，RMUX 见 `docs/cheatsheet/rmux.md`。

**Fedora / RHEL 系（含 TencentOS 等）**

```bash
bash scripts/linux-fedora/install.sh   # 安装 yazi / fd / fzf / lazygit / glow / eza（helix 见文档 4.1 节手动编译）
bash scripts/shared/bootstrap.sh       # 链接配置（tmux < 3.1 自动改链 ~/.tmux.conf）
```

然后在 `~/.bashrc` 末尾加载 shell 环境（见 `docs/linux-fedora-toolchain.md` 第 4.2 节）。安装细节与踩坑见 `docs/linux-fedora-toolchain.md`，两平台工具差异见 `docs/toolchain.yaml`。

## 前缀键

RMUX 与 tmux 都保持出厂默认 `C-b`，不做自定义。两份配置的前缀键小节只留有注释说明，没有 `set -g prefix` 或 `unbind` 语句。

如果以后想改成 `C-a`，在 `config/tmux/tmux.conf` 和 `config/rmux/rmux.conf` 的前缀键小节加入：

```tmux
unbind C-b
set -g prefix C-a
bind C-a send-prefix
```

## 配置风格约定

- RMUX / tmux：前缀键保持默认 `C-b`。RMUX 为 vi 风格移动、面板从当前目录分裂、鼠标默认关闭（`C-b T` 按需开启）；tmux 为 linux-fedora 实测的**极简配置**（鼠标开启、history 50000、新窗口/分屏继承当前目录），copy-mode 保持默认 emacs 风格（搜索 `C-s` / `C-r`）。
- eza：`ll` / `lt` / `lg` 为 linux-fedora 实测参数（无 `--icons`，ssh 终端常无 Nerd Font）；其余别名带图标、目录优先、Git 状态。
- glow：暗色自适应、`width: 0` 跟随终端宽度（v3 有 120 列硬上限，突破用 `GLOW_WIDTH`）。
- yazi：字母序排序、目录优先、预览开启；markdown 用 glow、目录用 eza 插件预览，git 角标三件套（fetchers + init.lua + theme `[git]` 段）；`gf` 平铺视图（fd）、`gi` lazygit、`gv` 变更文件、`z` 模糊搜索（fzf）。
- helix：gruvbox 主题、相对行号、系统剪贴板走 OSC 52 + tmux buffer（ssh 远程场景）。

> 版本基线：rmux `0.10+`、yazi `26.9.1+`、eza `0.20+`、glow `3.x`、tmux `2.7+`（linux-fedora 实测；XDG 配置路径需 `3.1+`）、helix `25.07+`、fd `10.x`、fzf `0.75+`、lazygit `0.66+`。升级工具后若出现未知字段提示，对照官方文档删去对应键即可。
