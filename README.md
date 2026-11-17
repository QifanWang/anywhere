# anywhere

跨平台现代 TUI 工具的**私人配置集合**。仓库中只保存「配置源文件」，由引导脚本把它们链接/复制到各平台的实际配置目录。

## 目录约定

- `docs/`、`scripts/` 按平台分层：`shared/` 放通用内容，`win11/`、`mac/`、`linux-fedora/` 放平台专属的安装指南与脚本。
- `config/` **不按平台分层**，只按工具命名：`config/tmux/`、`config/rmux/`、`config/eza/` 等。
- 工具配置尽量共用同一份文件；确实无法共用时，把变体放在同一工具目录内，并在文件头部写清适用平台。例如 `eza/aliases.sh`（bash/zsh）与 `eza/aliases.ps1`（PowerShell）、`tmux/tmux.conf`（非 win11）与 `rmux/rmux.conf`（win11）。

| 工具 | 用途 | 配置源文件 | 适用平台 |
| --- | --- | --- | --- |
| [RMUX](https://github.com/Helvesec/rmux) | 终端复用、会话保持 | `config/rmux/rmux.conf` | win11 |
| [tmux](https://github.com/tmux/tmux) | 终端复用、会话保持 | `config/tmux/tmux.conf` | macOS / Linux / WSL |
| [eza](https://github.com/eza-community/eza) | 现代 `ls` 替代品 | `config/eza/aliases.sh`、`config/eza/aliases.ps1` | 全平台（按 shell 选文件） |
| [glow](https://github.com/charmbracelet/glow) | 终端 Markdown 阅读器 | `config/glow/glow.yml` | 全平台 |
| [yazi](https://github.com/sxyazi/yazi) | 终端文件管理器 | `config/yazi/*.toml` | 全平台 |

## 目录结构

```
anywhere/
├── README.md
├── docs/
│   ├── CHEATSHEET.md              # 跨平台通用命令速查
│   ├── win11/
│   │   ├── INSTALL.md             # Windows 11 安装指南
│   │   └── CHEATSHEET.md          # RMUX 速查表
│   ├── mac/                       # 待补充 macOS 安装指南
│   └── linux-fedora/              # 待补充 Fedora 安装指南
├── config/                        # 只按工具分目录，无平台子目录
│   ├── rmux/rmux.conf
│   ├── tmux/tmux.conf
│   ├── eza/{aliases.sh,aliases.ps1}
│   ├── glow/glow.yml
│   └── yazi/{yazi,keymap,theme}.toml
└── scripts/
    ├── shared/bootstrap.sh        # XDG 链接（mac / linux-fedora 复用）
    ├── win11/
    │   ├── install.ps1            # 安装 rmux / eza / glow / yazi
    │   └── bootstrap.ps1          # 链接配置
    ├── mac/                       # 预留：macOS 安装脚本
    └── linux-fedora/              # 预留：Fedora 安装脚本
```

`mac/` 与 `linux-fedora/` 目前只放目录说明文件，尚未编写安装脚本与指南。

## 快速开始

**Windows 11（PowerShell）**

```powershell
.\scripts\win11\install.ps1       # 安装 rmux / eza / glow / yazi
.\scripts\win11\bootstrap.ps1     # 把配置链接到 $HOME\.config 与 %APPDATA%
```

然后在 PowerShell 配置文件中加载 eza 别名（见 `docs/win11/INSTALL.md` 第 5 节）。RMUX 命令见 `docs/win11/CHEATSHEET.md`。

**macOS / Fedora / WSL**

```bash
bash scripts/shared/bootstrap.sh
```

各平台的软件安装命令分别放在 `docs/<平台>/INSTALL.md`；目前只有 `win11` 已写好。

## 前缀键

RMUX 与 tmux 都保持出厂默认 `C-b`，不做自定义。两份配置的前缀键小节只留有注释说明，没有 `set -g prefix` 或 `unbind` 语句。

如果以后想改成 `C-a`，在 `config/tmux/tmux.conf` 和 `config/rmux/rmux.conf` 的前缀键小节加入：

```tmux
unbind C-b
set -g prefix C-a
bind C-a send-prefix
```

## 配置风格约定

- RMUX / tmux：前缀键保持默认 `C-b`，vi 风格移动，面板从当前目录分裂；RMUX 鼠标默认关闭，用 `C-b T` 按需开启。
- eza：默认带图标、分组目录优先、Git 状态、长格式时间。
- glow：暗色自适应，宽度 100，TUI 启用鼠标。
- yazi：自然排序、目录优先、预览开启；Windows 用 VS Code / Unix 用 `$EDITOR` 打开文件，平台差异写在配置条目的 `for` 字段里。

> 版本基线：rmux `0.10+`、yazi `26.9.1+`、eza `0.20+`、glow `2.x`、tmux `3.2+`。升级工具后若出现未知字段提示，对照官方文档删去对应键即可。
