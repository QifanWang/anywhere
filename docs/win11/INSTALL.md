# Windows 11 安装指南

平台专属文档，位于 `docs/win11/`。**win11 使用 RMUX 作为终端复用器，不使用 tmux**；tmux 配置保留在 `config/tmux/`，供其他平台使用。

通用命令速查见 `../CHEATSHEET.md`；RMUX 专属速查见 `CHEATSHEET.md`。

适用环境：Windows 10 / 11，PowerShell 7（推荐）或 Windows PowerShell 5.1。

## 1. 先准备终端与字体

1. 安装 **Windows Terminal**：`winget install --id Microsoft.WindowsTerminal -e`
2. 安装 **Nerd Font**（eza / yazi 的图标依赖它）：

```powershell
scoop bucket add nerd-fonts
scoop search FiraCode        # 找到形如 FiraCode-NF / FiraCode-NF-Mono 的包名
scoop install FiraCode-NF-Mono
```

也可以直接从 <https://www.nerdfonts.com/> 下载安装。安装后在 Windows Terminal 设置里把字体设为 `* Nerd Font Mono`，并开启 GPU 渲染。

3. 验证包管理器：

```powershell
winget --version
```

Scoop（推荐）：

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
irm get.scoop.sh | iex
```

## 2. 各工具安装方式对比

| 工具 | Scoop | winget | Chocolatey | 备注 |
| --- | --- | --- | --- | --- |
| rmux | `scoop install rmux`（先加 bucket） | `winget install rmux` | `choco install rmux` | 原生 Windows，无需 WSL |
| eza | `scoop install eza` | `winget install --id eza.eza` | `choco install eza` | |
| glow | `scoop install glow` | `winget install --id charmbracelet.glow` | `choco install glow` | |
| yazi | `scoop install yazi` | `winget install --id sxyazi.yazi` | `choco install yazi` | winget ID 可能变化，先 search |

一键安装（Scoop 路径，脚本会自动添加 rmux bucket）：

```powershell
scoop bucket add rmux https://github.com/Helvesec/scoop-rmux
scoop install rmux eza glow yazi
```

仓库脚本会按检测到的包管理器安装并提供确认提示：

```powershell
.\scripts\win11\install.ps1
```

## 3. RMUX 安装要点

RMUX 是 Rust 编写的终端复用器，使用原生 ConPTY 与命名管道，**不需要 WSL、不需要 MSYS2**，配置语法与 tmux 兼容。

```powershell
# 三选一
winget install rmux
# 或
scoop bucket add rmux https://github.com/Helvesec/scoop-rmux
scoop install rmux
# 或
choco install rmux
rmux -V
```

如果从 GitHub Release 手动解压 `.zip`，必须保持 `rmux.exe`、`rmux-daemon.exe` 与 `libexec/rmux/rmux.exe` 的相对结构，并把包根目录加入 `PATH`；只复制外层 `rmux.exe` 不算完整安装。排查 CLI 兼容问题时可设置 `$env:RMUX_DISABLE_TINY_CLI = 1`。

## 4. 链接配置

在仓库根目录运行：

```powershell
.\scripts\win11\bootstrap.ps1
```

脚本会：

- 把 `config/rmux` 链接到 `$HOME\.config\rmux` 与 `%APPDATA%\rmux`
- 把 `config/glow`、`config/yazi` 链接到 XDG 路径与 `%APPDATA%` 对应目录
- 优先创建**目录联接（Junction）**，失败时回退为复制
- 已有配置会先备份为 `.bak`

RMUX 的配置查找顺序（命中第一个即停止）：

1. `%XDG_CONFIG_HOME%\rmux\rmux.conf`
2. `%USERPROFILE%\.rmux.conf`
3. `%APPDATA%\rmux\rmux.conf`
4. `%RMUX_CONFIG_FILE%`

如果脚本被系统策略拦截，可手动复制：

```powershell
$repo = (Get-Location).Path
New-Item -ItemType Directory -Force "$HOME\.config\rmux","$HOME\.config\glow","$HOME\.config\yazi" | Out-Null
Copy-Item "$repo\config\rmux\rmux.conf"    "$HOME\.config\rmux\rmux.conf" -Force
Copy-Item "$repo\config\glow\glow.yml"     "$HOME\.config\glow\glow.yml" -Force
Copy-Item "$repo\config\yazi\*.toml"       "$HOME\.config\yazi\" -Force
```

> RMUX 在没有自身配置时会回退读取 tmux.conf；本仓库已提供原生 `rmux.conf`，因此不会走回退路径。

## 5. 让 eza 别名在 PowerShell 中生效

打开 PowerShell 配置文件：

```powershell
notepad $PROFILE
```

若提示文件不存在，先创建：

```powershell
New-Item -ItemType File -Path $PROFILE -Force | Out-Null
```

追加以下内容（路径按实际仓库位置调整）：

```powershell
$env:XDG_CONFIG_HOME = "$HOME\.config"
. "C:\Users\<你>\anywhere\config\eza\aliases.ps1"
```

重新打开终端后可用 `ll`、`la`、`lt`、`lg` 验证。

## 6. 验证安装

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

## 7. 常见问题：Chocolatey 的 warning 不是安装失败

如果看到类似下面的输出，注意 `0 error(s)` —— 这是 **warning**，Chocolatey 校验已通过，包可能已经装好：

```text
3 validations performed. 2 success(es), 1 warning(s), and 0 error(s).
Validation Warnings:
 - A pending system reboot request has been detected, however, this is being ignored...
Chocolatey detected you are not running from an elevated command shell...
```

处理方式：

1. 先确认到底装没装：重新打开终端，执行第 6 节的四条版本命令；或 `choco list --local-only` 查看已安装包。
2. **待重启请求**：Chocolatey 默认忽略它，但后续安装可能异常。方便时重启 Windows，再重跑 `.\scripts\win11\install.ps1` 做一次幂等安装。若希望遇到待重启就中止，可执行 `choco feature enable --name="exitOnRebootDetected"`，或在命令后加 `--exit-when-reboot-detected`。
3. **非管理员 shell**：多数 Chocolatey 包需要管理员权限。最省事的替代是改用 winget（Win11 自带）或 Scoop；脚本会优先用它们。确实要用 Chocolatey，就“以管理员身份运行”PowerShell 后重试。
4. 只能在非管理员环境使用时，Chocolatey 官方要求安装到非默认目录，例如安装阶段设置 `$env:ChocolateyInstall='C:\ProgramData\chocoportable'`；且通常只能装 `*.portable` 包。参考 <https://docs.chocolatey.org/en-us/choco/setup#non-administrative-install>。
