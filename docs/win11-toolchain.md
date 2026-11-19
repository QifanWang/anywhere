# Windows 11 工具链

## 1. 前置说明

平台工具链文档：`docs/win11-toolchain.md`。跨平台工具/功能对照见 [toolchain.yaml](toolchain.yaml)，命令速查见 `cheatsheet/`，其中 RMUX 见 `cheatsheet/rmux.md`。

| 项 | 值 |
| --- | --- |
| 系统 | Windows 11 |
| 关键约束 | winget 可用但需大陆镜像；终端复用器走原生 ConPTY，不依赖 WSL / MSYS2 |
| 策略 | 统一用 winget；`bootstrap.ps1` 负责配置链接与 PATH 补齐 |

前提：PowerShell 7 已安装（脚本本身依赖它运行，不纳入安装范围）。

包管理器统一用 winget：Windows 11 内置、可用脚本静默安装，便于在新设备上复现完全一致的软件清单。终端用 Windows Terminal。两者的安装与配置见 §3.1。

## 2. 工具与功能

每个工具承载的功能及跨平台对照见 [toolchain.yaml](toolchain.yaml)。

| 工具 | 承载功能 | 安装方式 | 配置源 | 本地备注 |
| --- | --- | --- | --- | --- |
| Shell（PowerShell 7） | 命令执行环境 | 前提已装 | — | 每个平台唯一；脚本运行环境，不纳入安装范围 |
| 字体（Nerd Font） | 终端图标渲染 | 手动下载 | Windows Terminal 字体设置 | 例如 FiraCode Nerd Font；作用于终端而非 Shell，`install.ps1` 不负责字体 |
| RMUX | 终端复用、会话保持 | `Helvesec.RMUX` | `../config/rmux/rmux.conf` | 原生 ConPTY；命令见 `cheatsheet/rmux.md` |
| eza | 目录列表 | `eza-community.eza` | `../config/eza/aliases.ps1` | 旧 ID `eza.eza` 不存在；别名见 §3.2 |
| glow | Markdown 阅读 / 预览 | `charmbracelet.glow` | `../config/glow/glow.yml` | v3；非 TTY 走 stdin |
| yazi | 文件管理、预览 | `sxyazi.yazi` | `../config/yazi/` | `g f` / `g i` / `g v` 为 Unix 专用 |
| helix | 模态编辑器（`EDITOR`） | `Helix.Helix` | `../config/helix/config.toml` | 命令为 `hx` |
| fd | 文件查找 | `sharkdp.fd` | — | 无配置文件 |
| fzf | 模糊搜索 | `junegunn.fzf` | — | 无配置文件；`yazi` 的 `z` 依赖它 |
| lazygit | Git 面板 | `JesseDuffield.lazygit` | — | 无配置文件 |

本地注意事项：

- Shell 的历史命令与智能提示**当前不配置**。
- RMUX 配置查找顺序：`%XDG_CONFIG_HOME%\rmux\rmux.conf` → `%USERPROFILE%\.rmux.conf` → `%APPDATA%\rmux\rmux.conf` → `%RMUX_CONFIG_FILE%`。本仓库提供原生 `rmux.conf`，不会回退到 `tmux.conf`。
- `yazi` 的 `g f` / `g i` / `g v` 在 keymap 中声明 `for = "unix"`，win11 下不显示；`z` 模糊搜索依赖 fzf 二进制。

## 3. 安装、配置与验证

### 3.1 前置准备

在新设备上先运行前置准备脚本：

```powershell
.\scripts\win11\prepare.ps1
.\scripts\win11\prepare.ps1 -Yes   # 跳过确认提示
```

脚本要求在 PowerShell 7 中运行（启动时会检查），会检查 winget 并配置大陆镜像源（修改源需管理员权限）、安装 Windows Terminal、给出 Nerd Font 下载指引并验证终端。可重复运行；若仅确认源已是大陆镜像，不会改动。字体需按指引手动下载安装，脚本不代劳。

完成后进入 §3.2。

### 3.2 工具链

**安装**

```powershell
.\scripts\win11\install.ps1
.\scripts\win11\install.ps1 -Yes   # 跳过确认提示
```

脚本可重复运行：已安装的包会自动检查升级；若已是最新版（winget 返回 `0x8A15002B`），视为成功而不是失败。`install.ps1` 只检查 winget 是否存在，镜像源由 `prepare.ps1` 负责；它安装在 §2 列出的全部命令行工具（含 helix、fd、fzf、lazygit），但不安装字体。

若从 GitHub Release 手动解压 RMUX，必须保持 `rmux.exe`、`rmux-daemon.exe` 与 `libexec/rmux/rmux.exe` 的相对结构，并把包根目录加入 `PATH`；只复制外层 `rmux.exe` 不算完整安装。排查 CLI 兼容问题可设置 `$env:RMUX_DISABLE_TINY_CLI = 1`。

**配置链接**

在仓库根目录运行：

```powershell
.\scripts\win11\bootstrap.ps1
```

脚本会：

- 从注册表刷新会话 PATH，缺失时定位 winget 包目录并写入用户 PATH
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

**验证**

在**新开的** PowerShell 7 终端中运行（确保 PATH、`$PROFILE` 与配置链接已生效）：

```powershell
.\scripts\win11\verify.ps1
```

脚本检查 PowerShell 版本、命令与版本、`rmux` 键位、`ll` 别名和配置目录，逐项列出 PASS / FAIL；有失败项时退出码为 1。

脚本无法覆盖的交互项，手动确认：

- `rmux` 启动后按 `C-b ?` 查看键位；`C-b T` 可切换面板鼠标模式。
- `yazi` 启动后按 `~` 查看帮助，确认图标正常（Nerd Font 生效）。
- `glow README.md` 应以渲染后的 Markdown 输出。
- 输入 `ll` 应显示带图标的长列表（脚本已检查别名存在）。

**排错**

1. **找不到 eza**：winget 的包 ID 是 `eza-community.eza`，不是 `eza.eza`。可用 `winget search eza` 核对。
2. **搜索/下载超时**：用 `winget source list -n winget` 检查源；若“参数”不是大陆镜像，按 §3.1 的命令重新添加（需要管理员权限）。
3. **安装需要提权**：部分包会触发 UAC 或要求管理员权限，以管理员身份打开 PowerShell 后重试。
4. **已安装但命令未生效**：重开终端后再运行 `verify.ps1`；PowerShell 别名还需按本节的 `aliases.ps1` 步骤加载。
