# Windows 11 工具链

## 1. 前置说明

平台工具链文档：`docs/win11-toolchain.md`。跨平台工具/功能对照见 [toolchain.yaml](toolchain.yaml)，命令速查见 `cheatsheet/`，其中 RMUX 见 `cheatsheet/rmux.md`。

| 项 | 值 |
| --- | --- |
| 系统 | Windows 11 |
| 关键约束 | winget 可用但需大陆镜像；终端复用器走原生 ConPTY，不依赖 WSL / MSYS2 |
| 策略 | 外部 CLI 统一用 winget；PowerShell 模块（CompletionPredictor / PSFzf）走 PSGallery；`bootstrap.ps1` 负责配置链接与 PATH 补齐 |
| 代理 | 本地代理需监听 `http://127.0.0.1:7890`；`prepare.ps1` 在当前会话设置 `HTTP_PROXY` / `HTTPS_PROXY` |

前提：PowerShell 7 已安装（脚本本身依赖它运行，不纳入安装范围）。PowerShell 7 自带 PSReadLine 模块，历史搜索与输入提示由它承担，不需要单独安装。补全预测与 fzf 历史搜索由 PSGallery 模块 CompletionPredictor、PSFzf 提供，见 §3.2。yazi 依赖 `file(1)` 做 MIME 检测，Windows 上由 Git for Windows 自带的 `usr\bin\file.exe` 提供（见 §2），需安装 Git for Windows。

代理要求：安装前需在本机启动代理客户端并监听 `http://127.0.0.1:7890`（HTTP 代理）。`prepare.ps1` 会在当前 PowerShell 会话中设置 `$env:HTTP_PROXY` 与 `$env:HTTPS_PROXY`；若代理未启动，winget 下载可能失败，可在同一会话用 `Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY` 清除后重试。

外部 CLI 统一用 winget：Windows 11 内置、可用脚本静默安装，便于复现软件清单。终端用 Windows Terminal，安装与配置见 §3.1。例外是 PSReadLine 的插件生态：CompletionPredictor 与 PSFzf 只发布在 PSGallery，由 `install.ps1` 经 `Install-Module` 安装（见 §3.2）。

## 2. 工具与功能

每个工具承载的功能及跨平台对照见 [toolchain.yaml](toolchain.yaml)。

| 工具 | 承载功能 | 安装方式 | 配置源 | 本地备注 |
| --- | --- | --- | --- | --- |
| Shell（PowerShell 7） | 命令执行环境 | 前提已装 | `../config/shell/profile.ps1` | 每个平台唯一；脚本运行环境，不纳入安装范围；交互配置见 §3.2 |
| 字体（Nerd Font） | 终端图标渲染与提示符字形 | 手动下载 | Windows Terminal 字体设置 | 例如 FiraCode Nerd Font；作用于终端而非 Shell，`install.ps1` 不负责字体 |
| PSReadLine | 历史搜索与输入提示 | PowerShell 7 内置模块 | `../config/shell/profile.ps1` | 上下键前缀搜索、Tab 菜单补全、`HistoryAndPlugin` 预测 + `ListView`；版本随 PowerShell 7 |
| oh-my-posh | 提示符 | `JanDeDobbeleer.OhMyPosh` | `../config/oh-my-posh/anywhere.omp.json` | 主题与 yazi 同为 Catppuccin 风格；需要 Nerd Font |
| zoxide | 目录跳转 | `ajeetdsouza.zoxide` | `../config/shell/profile.ps1` | `z <关键词>` 直达，`zi` 交互选择（复用 fzf）；接管 `cd` |
| RMUX | 终端复用、会话保持 | `Helvesec.RMUX` | `../config/rmux/rmux.conf` | 原生 ConPTY；命令见 `cheatsheet/rmux.md` |
| eza | 目录列表 | `eza-community.eza` | `../config/eza/aliases.ps1` | 旧 ID `eza.eza` 不存在；别名见 §3.2 |
| glow | Markdown 阅读 / 预览 | `charmbracelet.glow` | `../config/glow/glow.yml` | v3；非 TTY 走 stdin |
| yazi | 文件管理、预览 | `sxyazi.yazi` | `../config/yazi/` | `g f` / `g i` / `g v` 为 Unix 专用；markdown 的 `o` 精读走 `scripts/glow.ps1 -Pager` 全屏分页（`q` 回 yazi）；依赖 `file` 做 MIME 检测，见下一行 |
| `file`（Git 自带） | yazi 的 MIME 检测（决定 opener / previewer） | 随 Git for Windows 安装 | `YAZI_FILE_ONE` 环境变量 | yazi 唯一必需依赖；`bootstrap.ps1` 定位 `usr\bin\file.exe` 并写入用户环境变量；不推荐 winget / scoop / choco 版 |
| helix | 模态编辑器（`EDITOR`） | `Helix.Helix` | `../config/helix/config.toml` | 命令为 `hx` |
| fd | 文件查找 | `sharkdp.fd` | — | 无配置文件；yazi 的 `g f` 平铺视图与 fzf 候选源（`FZF_DEFAULT_COMMAND`）依赖它 |
| fzf | 模糊搜索 | `junegunn.fzf` | — | 无配置文件；`yazi` 的 `z`、zoxide 的 `zi`、PSFzf 的 `Ctrl+R` 都依赖它 |
| lazygit | Git 面板 | `JesseDuffield.lazygit` | — | 无配置文件；在 yazi 里按 `g i` 以前台（`shell --block`）拉起 |
| CompletionPredictor | PSReadLine 补全预测插件 | PSGallery：`Install-Module CompletionPredictor` | PowerShell 子系统插件，无配置文件 | 需 PowerShell 7.2+ / PSReadLine 2.2.2+；由 `profile.ps1` 导入，叠加到 `HistoryAndPlugin` |
| PSFzf | Ctrl+R 模糊历史搜索 | PSGallery：`Install-Module PSFzf` | — | 依赖 fzf 二进制；由 `profile.ps1` 经 `Set-PsFzfOption -PSReadlineChordReverseHistory` 接管 `Ctrl+R` |

本地注意事项：

- Shell 交互四项各有归属：**历史搜索 / 输入提示**用 PowerShell 7 内置的 PSReadLine + PSGallery 插件；**提示符**用 oh-my-posh；**目录跳转**用 zoxide；**eza 别名**沿用 `config/eza/aliases.ps1`。四项由 `../config/shell/profile.ps1` 统一加载，用户 `$PROFILE` 只需一行 dot-source（见 §3.2）。同一文件还提供 `y` / `yg` / `gw` 三个 yazi wrapper，与 Unix 的 `env.sh` 对齐。
- PSReadLine 随 PowerShell 7 分发，不通过 winget 安装，也不纳入 winget 清单。两个增强模块 CompletionPredictor（补全预测）与 PSFzf（Ctrl+R 模糊历史搜索）从 PSGallery 安装，由 `install.ps1` 的 Shell integration 段经 `Install-Module -Scope CurrentUser` 装上；已安装时会跳过，升级用 `Update-Module`。`PredictionSource` 默认是 `None`，预测实际由 `profile.ps1` 设置，并非「2.2.6+ 默认开启」。
- `ListView` 下按 `F2` 可在列表/行内视图间切换，`F4` 显示完整 tooltip；上下键在前缀历史搜索与预测列表导航间共用。`Ctrl+R` 由 PSFzf 接管为 fzf 模糊搜索；插件或 fzf 缺失时自动退回内置行为（历史预测 / 内置反向搜索），不会让 shell 启动失败。
- RMUX 配置查找顺序：`%XDG_CONFIG_HOME%\rmux\rmux.conf` → `%USERPROFILE%\.rmux.conf` → `%APPDATA%\rmux\rmux.conf` → `%RMUX_CONFIG_FILE%`。本仓库提供原生 `rmux.conf`，不会回退到 `tmux.conf`。
- yazi 的 `g f`（fd 平铺视图）/ `g i`（lazygit）/ `g v`（vcs-files 变更文件）三项工作流增强已开放到全平台，依赖 fd / lazygit / git + vcs-files.yazi 插件在 win11 上已齐备；`z` 模糊搜索依赖 fzf 二进制，候选源由 `profile.ps1` 中的 `FZF_DEFAULT_COMMAND` 指定为 fd（对齐 Unix 的 `env.sh`）。
- yazi 依赖 `file(1)` 判定 MIME（进而决定 opener / previewer），这是它的唯一必需前置依赖，但**不在 winget 清单里**：Windows 上用 Git for Windows 自带的 `usr\bin\file.exe`，需通过 `YAZI_FILE_ONE` 告诉 yazi 路径（原生 yazi 进程看不到 Git Bash 的 PATH）。`bootstrap.ps1` 会自动定位并持久化设置，`verify.ps1` 会检查；已有有效值则保留。官方不推荐 scoop / choco 版的 `file`（Unicode 文件名与部分参数支持有缺陷）。
- markdown 的 `o` 精读与光标预览在 win11 走 `config/yazi/scripts/glow.ps1`（由 `pwsh` 调用，不依赖 sh / sed / less）：预览用默认输出模式供 yazi 读取，`o` 用 `-Pager` 全屏分页（`space/f` 下一页、`b` 上一页、`j/k` 单行、`q` 退出），对应 Unix 的 `less -R`。脚本显式固定 UTF-8，避免从 `cmd /C` 启动时中文乱码。hx opener 已取消平台限制；该脚本随整个 `config/yazi/` 目录一起链接。

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

脚本可重复运行：已安装的包会自动检查升级；若已是最新版（winget 返回 `0x8A15002B`），视为成功而不是失败。`install.ps1` 只检查 winget 是否存在，镜像源由 `prepare.ps1` 负责；它安装在 §2 列出的全部 winget 工具（含 helix、fd、fzf、lazygit、zoxide、oh-my-posh），但不安装字体、`file` 与 PSReadLine（PowerShell 7 内置）。`file` 来自 Git for Windows，路径由 `bootstrap.ps1` 配置，见下。

同一脚本末尾还会经 PSGallery 安装两个 PSReadLine 增强模块（PSGallery 是例外，不纳入 winget）：

```powershell
Install-Module -Name CompletionPredictor -Scope CurrentUser -Force -Repository PSGallery
Install-Module -Name PSFzf              -Scope CurrentUser -Force -Repository PSGallery
```

已安装则跳过；手动安装/升级用上面的命令或 `Update-Module CompletionPredictor, PSFzf`。PSGallery 走 HTTPS，若下载受限需在当前会话设置与 §3.1 相同的代理环境变量（或先运行 `prepare.ps1` 以继承代理）。`CompletionPredictor` 要求 PowerShell 7.2+ 与 PSReadLine 2.2.2+；`PSFzf` 依赖 winget 装的 `fzf` 在 PATH 中。

若从 GitHub Release 手动解压 RMUX，必须保持 `rmux.exe`、`rmux-daemon.exe` 与 `libexec/rmux/rmux.exe` 的相对结构，并把包根目录加入 `PATH`；只复制外层 `rmux.exe` 不算完整安装。排查 CLI 兼容问题可设置 `$env:RMUX_DISABLE_TINY_CLI = 1`。

**快速启动 rmux 会话**

`start-rmux.ps1` 一键开一个**命名** rmux 会话：新建 Windows Terminal 窗口、**左右分屏**两个面板、并 attach 进去。会话名不能含空白；同名会话已存在时会报错（先 `rmux kill-session -t <name>` 或换名）。

```powershell
.\scripts\win11\start-rmux.ps1                      # 会话名 dev，起始目录 = 当前目录
.\scripts\win11\start-rmux.ps1 -Name work            # 命名会话 work
.\scripts\win11\start-rmux.ps1 -Name demo -Directory D:\proj -Title "Demo"
.\scripts\win11\start-rmux.ps1 -Name dev -NoWindow   # 不开新窗口，在当前终端 attach（无 wt 时）
```

脚本先在后台创建 detached 会话并分屏，再用 `wt -w new new-tab --title ... pwsh -Command "rmux attach -t <name>"` 在新窗口接入，因此 attach 命令无复杂转义。需要终端复用器基础键位见 `cheatsheet/rmux.md`。

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
- 定位 Git for Windows 自带的 `usr\bin\file.exe`，设置持久化的 `YAZI_FILE_ONE`（已有有效值则保留；`-WhatIf` 可预览）
- 优先创建**目录联接（Junction）**，失败时回退为复制；已指向同一源目录的链接会跳过
- 已有配置会先备份为 `.bak`（备份本身是链接时只删除链接，不会误删源目录）
- 在 `$PROFILE.CurrentUserAllHosts` 中**幂等注入**一行 dot-source（带 marker，重复运行不会叠加）；若任一 profile 变体已有引用则跳过
- 支持 `-SkipProfile` 完全跳过 profile 修改，`-ProfileTarget` 指定注入到其它变体，`-WhatIf` 预览改动

`profile.ps1` 内部按"工具存在才初始化"的顺序加载：eza 别名 → PSReadLine（前缀历史搜索 / Tab 菜单补全 / `HistoryAndPlugin` + `ListView` 预测 / PSFzf 接管 `Ctrl+R`）→ zoxide（接管 `cd`）→ oh-my-posh（提示符）→ 定义 `y` / `yg` / `gw` wrapper（依赖 yazi / glow，与 Unix `env.sh` 对齐）。任何一项缺失都不会让 shell 启动失败。

注入的 managed block 形如：

```powershell
# >>> anywhere:shell-profile >>>
. "$env:XDG_CONFIG_HOME\shell\profile.ps1"
# <<< anywhere:shell-profile <<<
```

因为写在 `CurrentUserAllHosts`（`Profile.ps1`），`pwsh` 与 VS Code 等宿主都会加载；它先于 `CurrentUserCurrentHost`（`$PROFILE`）执行，所以用户自己的 `$PROFILE` 仍可覆盖仓库配置。

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

若使用了 `-SkipProfile` 或手动复制，还需自行在目标 profile 中加入上面的 managed block；bootstrap 正常执行时会自动注入。

**验证**

在**新开的** PowerShell 7 终端中运行（确保 PATH、`$PROFILE` 与配置链接已生效）：

```powershell
.\scripts\win11\verify.ps1
```

脚本检查 PowerShell 版本、命令与版本、`rmux` 键位、`ll` 别名、`$PROFILE` 中 `profile.ps1` 的加载行、PSReadLine / zoxide / oh-my-posh 的初始化状态与配置链接目录，以及 `y` / `yg` / `gw` wrapper、`YAZI_FILE_ONE` 是否已定义（仅在对应工具已安装时检查）。新增的 PSReadLine 检查包括 `CompletionPredictor` / `PSFzf` 是否已加载、`PredictionSource` 是否为 `HistoryAndPlugin`、`PredictionViewStyle` 是否为 `ListView`、`Ctrl+R` 是否交给 PSFzf。逐项列出 PASS / FAIL；有失败项时退出码为 1。

脚本无法覆盖的交互项，手动确认：

- `rmux` 启动后按 `C-b ?` 查看键位；鼠标默认为 `on`（滚轮滚动各面板历史、拖拽调整分屏），按 `C-b T` 可临时切回终端原生选择。开多个 panel 后用滚轮或 `C-b PPage` 进入复制模式滚动历史，详见 `cheatsheet/rmux.md`。
- `yazi` 启动后按 `~` 查看帮助，确认图标正常（Nerd Font 生效）；提示符应显示 oh-my-posh 的 git 分支与路径。
- 在 yazi 里按 `g f` 应进入 fd 平铺视图（最多 3 层）；按 `g v` 应进入 vcs:// 虚拟视图列出 Git 变更文件；按 `g i` 应以前台方式拉起 lazygit（`q` 退回 yazi）。
- `glow README.md` 应以渲染后的 Markdown 输出；在 yazi 里把光标移到 `.md` 文件，预览 pane 应显示 glow 渲染结果；按 `o` 应进入**全屏分页**的精读界面（底部有 `-- More --` 提示），`space` 翻页、`q` 退出回到 yazi，而不是把文本直接打印到终端。
- 输入 `ll` 应显示带图标的长列表（脚本已检查别名存在）。
- 输入 `z <关键词>` 能跳转常用目录、`zi` 能用 fzf 交互选择。
- 输入命令前缀后上下键按前缀搜历史、Tab 弹出补全菜单；输入时在下方出现 fish 风格下拉预测列表（`F2` 切换显隐、方向键选择、`F4` 看完整 tooltip），历史与补全建议混合显示。
- 按 `Ctrl+R` 应弹出 fzf 交互界面模糊搜索历史，选中后回填命令行；`q` / `Esc` 取消。插件缺失时会退回内置的反向增量搜索。
- 输入 `y` 浏览目录后按 `q` 退出，应自动 `cd` 到该目录（按 `Q` 不切换）；`yg` 选文件退出后应以 glow 精读；`gw README.md` 应按当前终端宽度渲染。

**排错**

1. **找不到 eza**：winget 的包 ID 是 `eza-community.eza`，不是 `eza.eza`。可用 `winget search eza` 核对。
2. **搜索/下载超时**：用 `winget source list -n winget` 检查源；若“参数”不是大陆镜像，按 §3.1 的命令重新添加（需要管理员权限）。
3. **安装需要提权**：部分包会触发 UAC 或要求管理员权限，以管理员身份打开 PowerShell 后重试。
4. **已安装但命令未生效**：重开终端后再运行 `verify.ps1`；shell 交互还需按本节的 `profile.ps1` 步骤在 `$PROFILE` 加载。
5. **下载超时且镜像已配置**：确认本地代理 `127.0.0.1:7890` 正在监听；若代理未运行，可在当前会话执行 `Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY` 后重试。
6. **`z` / `zi` 不生效**：确认 `$PROFILE` 已加载 `profile.ps1`（脚本会检查该行）；`zi` 还需 fzf 在 PATH 中。zoxide 接管 `cd` 后，原生 `cd` 的语义仍保留，只是额外记录访问历史。
7. **提示符没有颜色 / 图标乱码**：Windows Terminal 需配置 Nerd Font；oh-my-posh 主题读取 `XDG_CONFIG_HOME\oh-my-posh\anywhere.omp.json`，可用 `oh-my-posh config export --output -` 排查。
8. **输入预测不生效 / 没有下拉列表**：先确认是在**交互式**终端运行——输出被重定向（管道 / 自动化捕获）时 PSReadLine 会拒绝启用预测，`verify.ps1` 会给出提示并把相关项标为 FAIL，需到真实终端复核。再确认 `profile.ps1` 已加载（脚本会检查）且 `PredictionSource` 为 `HistoryAndPlugin`、`PredictionViewStyle` 为 `ListView`。用 `Get-Module PSReadLine | Select-Object Version` 确认版本 ≥ 2.2.2；旧版本上这两个选项会抛错并被 profile 的 try/catch 降级。`CompletionPredictor` 缺失时只会退化为纯 `History` 预测，不会报错。
9. **补全预测没有内容**：`CompletionPredictor` 需 PowerShell 7.2+ 且已由 profile 导入；用 `Get-Module CompletionPredictor` 确认。它是 PowerShell 子系统插件，重开终端后才注册。
10. **`Ctrl+R` 仍是内置反向搜索**：确认 `PSFzf` 已加载（`Get-Module PSFzf`）且 `fzf` 在 PATH（`Get-Command fzf`），缺一即保留内置键位。用 `Get-PSReadLineKeyHandler -Chord 'Ctrl+r'` 查看，接管后 `Function` 应为 `Fzf Reverse History Select`。也可用 `Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'` 手动绑定。
11. **yazi 里 `o` 不用 glow 渲染**：确认 `%APPDATA%\yazi\config\scripts\glow.ps1` 存在（bootstrap 链接整个 `config/yazi/` 目录，旧配置需重跑一次）；再手动试 `pwsh -NoProfile -File "%APPDATA%\yazi\config\scripts\glow.ps1" <某个 md 文件>`，能输出带颜色文本即脚本与 glow 正常，问题在 yazi 配置未刷新。
12. **PSGallery 安装失败**：确认 PSGallery 已注册（`Get-PSRepository PSGallery`）；下载超时需按 §3.1 设置代理，或手动运行 §3.2 的两条 `Install-Module`。
13. **yazi 的 MIME 规则不生效 / `.md` 预览或打开落到默认动作**：先确认 `YAZI_FILE_ONE` 已设置且指向存在的文件（`verify.ps1` 会检查）。yazi 用 `file(1)` 判定 MIME，Windows 上应是 Git for Windows 自带的 `C:\Program Files\Git\usr\bin\file.exe`；重跑 `bootstrap.ps1` 可自动设置，手动设置后需重开终端。不要用 scoop / choco 装的 `file`。
14. **`g f` / `g i` / `g v` 在 win11 无反应**：确认 `keymap.toml` 中三条已去掉 `for = "unix"`（bootstrap 链接整个 `config/yazi/`，改后需重跑一次；已在 yazi 中则重开）。`g i` 需 lazygit 在 PATH，`g f` 需 fd，`g v` 需 git + `plugins/vcs-files.yazi`。`g i` 若报 shell 相关错误，把 `run` 改为 `shell --block cmd /c lazygit` 重试。
15. **rmux 多 panel 无法滚轮 / 上下键滚动**：本仓库 `rmux.conf` 已默认 `mouse on`，确认运行中的 server 已加载配置（`rmux show-options -g mouse` 应为 `on`；刚改配置可用 `C-b r` 重载）。滚轮需在目标面板上操作；键盘滚动须按 `C-b PPage` 或 `C-b [` 进入复制模式后用 `↑/↓`/`j/k`/`PgUp/PgDn`，普通模式的裸 `↑/↓` 是 shell 命令历史、`C-b ↑/↓` 是切换面板。若想恢复终端原生双击选词，按 `C-b T` 关掉鼠标（再按一次切回）。
16. **按 `y` 进入 yazi 总是固定目录、不是当前 `cd` 的目录**：PowerShell 的 `cd` 不改进程原生 cwd，原生 yazi 继承的是 shell 启动目录。`profile.ps1` 的 `y` / `yg` wrapper 已把当前 PS location 作为 ENTRY 显式传给 yazi；若仍复现，确认已重开终端加载最新 profile，或检查是否用了不带修复的旧配置。详见 `cheatsheet/powershell.md`。
