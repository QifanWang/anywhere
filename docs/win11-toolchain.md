# Windows 11 工具链

## 1. 前置说明

平台工具链文档：`docs/win11-toolchain.md`。跨平台工具/功能对照见 [toolchain.yaml](toolchain.yaml)，命令速查见 `cheatsheet/`，其中 RMUX 见 `cheatsheet/rmux.md`。

| 项 | 值 |
| --- | --- |
| 系统 | Windows 11 |
| 关键约束 | winget 可用但需大陆镜像；终端复用器走原生 ConPTY，不依赖 WSL / MSYS2 |
| 策略 | 统一用 winget；`bootstrap.ps1` 负责配置链接与 PATH 补齐 |
| 代理 | 本地代理需监听 `http://127.0.0.1:7890`；`prepare.ps1` 在当前会话设置 `HTTP_PROXY` / `HTTPS_PROXY` |

前提：PowerShell 7 已安装（脚本本身依赖它运行，不纳入安装范围）。PowerShell 7 自带 PSReadLine 模块（2.2.6+ 默认启用预测），历史搜索与输入提示由它承担，不需要单独安装。

代理要求：安装前需在本机启动代理客户端并监听 `http://127.0.0.1:7890`（HTTP 代理）。`prepare.ps1` 会在当前 PowerShell 会话中设置 `$env:HTTP_PROXY` 与 `$env:HTTPS_PROXY`；若代理未启动，winget 下载可能失败，可在同一会话用 `Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY` 清除后重试。

包管理器统一用 winget：Windows 11 内置、可用脚本静默安装，便于在新设备上复现完全一致的软件清单。终端用 Windows Terminal。两者的安装与配置见 §3.1。

## 2. 工具与功能

每个工具承载的功能及跨平台对照见 [toolchain.yaml](toolchain.yaml)。

| 工具 | 承载功能 | 安装方式 | 配置源 | 本地备注 |
| --- | --- | --- | --- | --- |
| Shell（PowerShell 7） | 命令执行环境 | 前提已装 | `../config/shell/profile.ps1` | 每个平台唯一；脚本运行环境，不纳入安装范围；交互配置见 §3.2 |
| 字体（Nerd Font） | 终端图标渲染与提示符字形 | 手动下载 | Windows Terminal 字体设置 | 例如 FiraCode Nerd Font；作用于终端而非 Shell，`install.ps1` 不负责字体 |
| PSReadLine | 历史搜索与输入提示 | PowerShell 7 内置模块 | `../config/shell/profile.ps1` | 上下键前缀搜索、Tab 菜单补全、基于历史的预测；版本随 PowerShell 7 |
| oh-my-posh | 提示符 | `JanDeDobbeleer.OhMyPosh` | `../config/oh-my-posh/anywhere.omp.json` | 主题与 yazi 同为 Catppuccin 风格；需要 Nerd Font |
| zoxide | 目录跳转 | `ajeetdsouza.zoxide` | `../config/shell/profile.ps1` | `z <关键词>` 直达，`zi` 交互选择（复用 fzf）；接管 `cd` |
| RMUX | 终端复用、会话保持 | `Helvesec.RMUX` | `../config/rmux/rmux.conf` | 原生 ConPTY；命令见 `cheatsheet/rmux.md` |
| eza | 目录列表 | `eza-community.eza` | `../config/eza/aliases.ps1` | 旧 ID `eza.eza` 不存在；别名见 §3.2 |
| glow | Markdown 阅读 / 预览 | `charmbracelet.glow` | `../config/glow/glow.yml` | v3；非 TTY 走 stdin |
| yazi | 文件管理、预览 | `sxyazi.yazi` | `../config/yazi/` | `g f` / `g i` / `g v` 为 Unix 专用 |
| helix | 模态编辑器（`EDITOR`） | `Helix.Helix` | `../config/helix/config.toml` | 命令为 `hx` |
| fd | 文件查找 | `sharkdp.fd` | — | 无配置文件 |
| fzf | 模糊搜索 | `junegunn.fzf` | — | 无配置文件；`yazi` 的 `z` 与 zoxide 的 `zi` 都依赖它 |
| lazygit | Git 面板 | `JesseDuffield.lazygit` | — | 无配置文件 |

本地注意事项：

- Shell 交互四项各有归属：**历史搜索 / 输入提示**用 PowerShell 7 内置的 PSReadLine；**提示符**用 oh-my-posh；**目录跳转**用 zoxide；**eza 别名**沿用 `config/eza/aliases.ps1`。四项由 `../config/shell/profile.ps1` 统一加载，用户 `$PROFILE` 只需一行 dot-source（见 §3.2）。
- PSReadLine 随 PowerShell 7 分发，不通过 winget 安装，也不纳入 `install.ps1` 的清单；只需确认版本 ≥ 2.2.6（预测默认开启）。
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

脚本启动时设置 `$env:HTTP_PROXY` / `$env:HTTPS_PROXY` 为 `http://127.0.0.1:7890`。以 `.\scripts\win11\prepare.ps1` 方式运行时，脚本在**当前 PowerShell 进程**中执行，这两个环境变量会保留到脚本结束后，因此**同一会话**中后续调用 `install.ps1`、`bootstrap.ps1` 等脚本，以及它们启动的子进程（如 winget）都会继承代理设置。该设置是进程级的，不会写入用户环境变量；关闭终端、新开窗口，或用 `pwsh -File` 等独立进程方式运行时不会生效，需要重新设置。`verify.ps1` 只做本地检查，在新终端运行不受影响。

完成后进入 §3.2。

### 3.2 工具链

**安装**

```powershell
.\scripts\win11\install.ps1
.\scripts\win11\install.ps1 -Yes   # 跳过确认提示
```

脚本可重复运行：已安装的包会自动检查升级；若已是最新版（winget 返回 `0x8A15002B`），视为成功而不是失败。`install.ps1` 只检查 winget 是否存在，镜像源由 `prepare.ps1` 负责；它安装在 §2 列出的全部 winget 工具（含 helix、fd、fzf、lazygit、zoxide、oh-my-posh），但不安装字体，也不安装 PSReadLine（PowerShell 7 内置）。

若从 GitHub Release 手动解压 RMUX，必须保持 `rmux.exe`、`rmux-daemon.exe` 与 `libexec/rmux/rmux.exe` 的相对结构，并把包根目录加入 `PATH`；只复制外层 `rmux.exe` 不算完整安装。排查 CLI 兼容问题可设置 `$env:RMUX_DISABLE_TINY_CLI = 1`。

**配置链接**

在仓库根目录运行：

```powershell
.\scripts\win11\bootstrap.ps1
```

脚本会：

- 从注册表刷新会话 PATH，缺失时定位 winget 包目录并写入用户 PATH
- 把 `../config/eza/`、`../config/glow/`、`../config/helix/`、`../config/rmux/`、`../config/yazi/`、`../config/oh-my-posh/` 链接到 XDG 路径与 `%APPDATA%` 对应目录（yazi 为 `%APPDATA%\yazi\config`）
- 把 `../config/shell/profile.ps1` 链接为 XDG 下 `shell/profile.ps1`（**单文件链接**），其余 `config/shell/*` 不链接
- `../config/tmux/` 与 `../config/shell/env.sh` 只用于其他平台，Windows 不链接
- 设置持久化的 `XDG_CONFIG_HOME`（默认 `$HOME\.config`）并同步当前会话
- 优先创建**目录联接（Junction）**，失败时回退为复制；已指向同一源目录的链接会跳过
- 已有配置会先备份为 `.bak`（备份本身是链接时只删除链接，不会误删源目录）

`profile.ps1` 内部按"工具存在才初始化"的顺序加载：eza 别名 → PSReadLine（历史搜索 / 预测 / Tab 菜单补全）→ zoxide（接管 `cd`）→ oh-my-posh（提示符）。任何一项缺失都不会让 shell 启动失败。

在 PowerShell 配置文件（`$PROFILE`）中加载 `profile.ps1`（只需一次）：

```powershell
notepad $PROFILE                       # 若不存在，先执行 New-Item -ItemType File -Path $PROFILE -Force
. "$env:XDG_CONFIG_HOME\shell\profile.ps1"
```

> 之前手工写入的 `. "...\eza\aliases.ps1"` 可以删掉——`profile.ps1` 已包含它，重复 dot-source 无害但无必要。

若脚本被系统策略拦截，可手动复制：

```powershell
$repo = (Get-Location).Path
New-Item -ItemType Directory -Force "$HOME\.config\eza","$HOME\.config\glow","$HOME\.config\helix","$HOME\.config\rmux","$HOME\.config\yazi","$HOME\.config\oh-my-posh","$HOME\.config\shell" | Out-Null
Copy-Item "$repo\config\eza\aliases.ps1"        "$HOME\.config\eza\aliases.ps1" -Force
Copy-Item "$repo\config\glow\glow.yml"          "$HOME\.config\glow\glow.yml" -Force
Copy-Item "$repo\config\helix\config.toml"      "$HOME\.config\helix\config.toml" -Force
Copy-Item "$repo\config\rmux\rmux.conf"         "$HOME\.config\rmux\rmux.conf" -Force
Copy-Item "$repo\config\yazi\*.toml"            "$HOME\.config\yazi\" -Force
Copy-Item "$repo\config\oh-my-posh\*.json"      "$HOME\.config\oh-my-posh\" -Force
Copy-Item "$repo\config\shell\profile.ps1"      "$HOME\.config\shell\profile.ps1" -Force
```

**验证**

在**新开的** PowerShell 7 终端中运行（确保 PATH、`$PROFILE` 与配置链接已生效）：

```powershell
.\scripts\win11\verify.ps1
```

脚本检查 PowerShell 版本、命令与版本、`rmux` 键位、`ll` 别名、`$PROFILE` 中 `profile.ps1` 的加载行、PSReadLine / zoxide / oh-my-posh 的配置链接与目录，逐项列出 PASS / FAIL；有失败项时退出码为 1。

脚本无法覆盖的交互项，手动确认：

- `rmux` 启动后按 `C-b ?` 查看键位；`C-b T` 可切换面板鼠标模式。
- `yazi` 启动后按 `~` 查看帮助，确认图标正常（Nerd Font 生效）；提示符应显示 oh-my-posh 的 git 分支与路径。
- `glow README.md` 应以渲染后的 Markdown 输出。
- 输入 `ll` 应显示带图标的长列表（脚本已检查别名存在）。
- 输入 `z <关键词>` 能跳转常用目录、`zi` 能用 fzf 交互选择；上下键按前缀搜历史、Tab 弹出补全菜单、输入时显示灰色预测。

**排错**

1. **找不到 eza**：winget 的包 ID 是 `eza-community.eza`，不是 `eza.eza`。可用 `winget search eza` 核对。
2. **搜索/下载超时**：用 `winget source list -n winget` 检查源；若“参数”不是大陆镜像，按 §3.1 的命令重新添加（需要管理员权限）。
3. **安装需要提权**：部分包会触发 UAC 或要求管理员权限，以管理员身份打开 PowerShell 后重试。
4. **已安装但命令未生效**：重开终端后再运行 `verify.ps1`；shell 交互还需按本节的 `profile.ps1` 步骤在 `$PROFILE` 加载。
5. **下载超时且镜像已配置**：确认本地代理 `127.0.0.1:7890` 正在监听；若代理未运行，可在当前会话执行 `Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY` 后重试。
6. **`z` / `zi` 不生效**：确认 `$PROFILE` 已加载 `profile.ps1`（脚本会检查该行）；`zi` 还需 fzf 在 PATH 中。zoxide 接管 `cd` 后，原生 `cd` 的语义仍保留，只是额外记录访问历史。
7. **提示符没有颜色 / 图标乱码**：Windows Terminal 需配置 Nerd Font；oh-my-posh 主题读取 `XDG_CONFIG_HOME\oh-my-posh\anywhere.omp.json`，可用 `oh-my-posh config export --output -` 排查。
8. **历史搜索无预测**：确认 PSReadLine 版本（`Get-Module PSReadLine | Select-Object Version`），低于 2.2.6 时预测不会默认开启，可 `Update-Module PSReadLine` 后重开终端。
