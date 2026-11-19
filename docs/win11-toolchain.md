# Windows 11 工具链

平台工具链文档：`docs/win11-toolchain.md`。跨平台工具/功能对照见 [toolchain.yaml](toolchain.yaml)，命令速查见 `cheatsheet/`，其中 RMUX 见 `cheatsheet/rmux.md`。

| 项 | 值 |
| --- | --- |
| 系统 | Windows 10 / 11 |
| Shell | PowerShell 7（推荐）或 Windows PowerShell 5.1 |
| 关键约束 | winget 可用但需大陆镜像；终端复用器走原生 ConPTY，不依赖 WSL / MSYS2 |
| 策略 | 统一用 winget；`bootstrap.ps1` 负责配置链接与 PATH 补齐 |

两份工具链文档（`win11-toolchain.md` 与 `linux-fedora-toolchain.md`）使用相同章节结构：

```text
1. 包管理器
2. 终端与 Shell
3. 工具与功能
4. 安装、配置与验证
```

## 1. 包管理器

win11 只使用 winget。安装脚本会检查大陆镜像源：

```powershell
winget --version
winget source list -n winget   # “参数”应指向大陆镜像，例如 https://mirrors.cernet.edu.cn/winget-source
```

若不是大陆镜像，以管理员身份执行（安装脚本也会自动检查并提示）：

```powershell
winget source remove winget
winget source add winget https://mirrors.cernet.edu.cn/winget-source --trust-level trusted
winget source update
```

一键安装：

```powershell
.\scripts\win11\install.ps1
.\scripts\win11\install.ps1 -Yes   # 跳过确认提示
```

脚本可重复运行：已安装的包会自动检查升级；若已是最新版（winget 返回 `0x8A15002B`），视为成功而不是失败。`install.ps1` 只安装命令行工具，不安装字体、helix、fd / fzf / lazygit。

## 2. 终端与 Shell

| 项 | 当前状态 |
| --- | --- |
| 终端 | Windows Terminal：`winget install --id Microsoft.WindowsTerminal -e` |
| 字体 | Nerd Font 手动安装，例如 FiraCode Nerd Font；在 Windows Terminal 里设为 `* Nerd Font Mono` 并开启 GPU 渲染 |
| Shell | PowerShell 7（推荐）或 Windows PowerShell 5.1 |
| PATH | `bootstrap.ps1` 从注册表刷新会话 PATH，缺失时定位 winget 包目录并写入用户 PATH |
| 历史命令 | **当前不配置** |
| 智能提示 | **当前不配置** |
| 别名 | `$PROFILE` 中 dot-source `$env:XDG_CONFIG_HOME\eza\aliases.ps1` 加载 eza 别名 |

Nerd Font 从 <https://www.nerdfonts.com/> 下载安装。安装脚本不负责字体。别名加载命令见 §4.2。

## 3. 工具与功能

本平台工具清单如下；每个工具承载的功能及跨平台对照见 [toolchain.yaml](toolchain.yaml)。

| 工具 | 承载功能 | 安装方式 | 配置源 | 本地备注 |
| --- | --- | --- | --- | --- |
| RMUX | 终端复用、会话保持 | `Helvesec.RMUX` | `../config/rmux/rmux.conf` | 原生 ConPTY；命令见 `cheatsheet/rmux.md` |
| eza | 目录列表 | `eza-community.eza` | `../config/eza/aliases.ps1` | 旧 ID `eza.eza` 不存在 |
| glow | Markdown 阅读 / 预览 | `charmbracelet.glow` | `../config/glow/glow.yml` | v3；非 TTY 走 stdin |
| yazi | 文件管理、预览 | `sxyazi.yazi` | `../config/yazi/` | `g f` / `g i` / `g v` 为 Unix 专用 |

本地注意事项：

- RMUX 配置查找顺序：`%XDG_CONFIG_HOME%\rmux\rmux.conf` → `%USERPROFILE%\.rmux.conf` → `%APPDATA%\rmux\rmux.conf` → `%RMUX_CONFIG_FILE%`。本仓库提供原生 `rmux.conf`，不会回退到 `tmux.conf`。
- helix、fd、fzf、lazygit 未纳入 `install.ps1`；需要时自行安装。其中 `yazi` 的 `z` 模糊搜索依赖 fzf 二进制。

## 4. 安装、配置与验证

### 4.1 安装

按 §1 执行 `install.ps1`。若从 GitHub Release 手动解压 RMUX，必须保持 `rmux.exe`、`rmux-daemon.exe` 与 `libexec/rmux/rmux.exe` 的相对结构，并把包根目录加入 `PATH`；只复制外层 `rmux.exe` 不算完整安装。排查 CLI 兼容问题可设置 `$env:RMUX_DISABLE_TINY_CLI = 1`。

### 4.2 配置链接

在仓库根目录运行：

```powershell
.\scripts\win11\bootstrap.ps1
```

脚本会：

- 把 `../config/eza/`、`../config/glow/`、`../config/helix/`、`../config/rmux/`、`../config/yazi/` 链接到 XDG 路径与 `%APPDATA%` 对应目录（yazi 为 `%APPDATA%\yazi\config`）
- `../config/tmux/` 与 `../config/shell/env.sh` 只用于其他平台，Windows 不链接
- 设置持久化的 `XDG_CONFIG_HOME`（默认 `$HOME\.config`）并同步当前会话
- 优先创建**目录联接（Junction）**，失败时回退为复制；已指向同一源目录的链接会跳过
- 已有配置会先备份为 `.bak`（备份本身是链接时只删除链接，不会误删源目录）

在 PowerShell 配置文件（`$PROFILE`）中加载 eza 别名（只需一次）：

```powershell
notepad $PROFILE                       # 若不存在，先执行 New-Item -ItemType File -Path $PROFILE -Force
. "$env:XDG_CONFIG_HOME\eza\aliases.ps1"
```

若脚本被系统策略拦截，可手动复制：

```powershell
$repo = (Get-Location).Path
New-Item -ItemType Directory -Force "$HOME\.config\eza","$HOME\.config\glow","$HOME\.config\helix","$HOME\.config\rmux","$HOME\.config\yazi" | Out-Null
Copy-Item "$repo\config\eza\aliases.ps1"   "$HOME\.config\eza\aliases.ps1" -Force
Copy-Item "$repo\config\glow\glow.yml"     "$HOME\.config\glow\glow.yml" -Force
Copy-Item "$repo\config\helix\config.toml" "$HOME\.config\helix\config.toml" -Force
Copy-Item "$repo\config\rmux\rmux.conf"    "$HOME\.config\rmux\rmux.conf" -Force
Copy-Item "$repo\config\yazi\*.toml"       "$HOME\.config\yazi\" -Force
```

### 4.3 验证

```powershell
rmux -V
rmux list-keys -N       # 确认前缀键与自定义键位已加载
eza --version
glow --version
yazi --version
```

- `rmux` 启动后按 `C-b ?` 查看键位；`C-b T` 可切换面板鼠标模式。
- `yazi` 启动后按 `~` 查看帮助，确认图标正常（Nerd Font 生效）。
- `glow README.md` 应以渲染后的 Markdown 输出。
- PowerShell 中输入 `ll` 应显示带图标的长列表。

### 4.4 排错

1. **找不到 eza**：winget 的包 ID 是 `eza-community.eza`，不是 `eza.eza`。可用 `winget search eza` 核对。
2. **搜索/下载超时**：用 `winget source list -n winget` 检查源；若“参数”不是大陆镜像，按 §1 的命令重新添加（需要管理员权限）。
3. **安装需要提权**：部分包会触发 UAC 或要求管理员权限，以管理员身份打开 PowerShell 后重试。
4. **已安装但命令未生效**：重开终端后再执行 §4.3 的验证命令；PowerShell 别名还需按 §4.2 加载 `aliases.ps1`。
