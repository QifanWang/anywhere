# PowerShell shell 交互（win11）

配置源文件：`../../config/shell/profile.ps1`。安装与配置链接见 `../win11-toolchain.md`；zoxide 单独见 `zoxide.md`。

`profile.ps1` 由 bootstrap 自动在 `$PROFILE.CurrentUserAllHosts` 注入一行 dot-source（`-SkipProfile` 可跳过），内部按"工具存在才初始化"加载：eza 别名 → PSReadLine → zoxide → oh-my-posh。

## PSReadLine（PowerShell 7 内置，历史搜索与提示）

| 按键 | 作用 |
| --- | --- |
| `↑` / `↓` | 按当前输入前缀搜索历史（非逐条翻阅） |
| `Tab` | 菜单式补全（MenuComplete） |
| 输入中灰色文字 | 基于历史的预测（InlineView）；`→` 接受，`Alt+F` 逐词接受 |
| `Ctrl+R` | 交互式历史搜索（PSReadLine 默认绑定） |

| 命令 | 作用 |
| --- | --- |
| `Get-Module PSReadLine \| Select-Object Version` | 查看版本（需 ≥ 2.2.6） |
| `Update-Module PSReadLine` | 升级后重开终端 |

## oh-my-posh（提示符）

| 命令 | 作用 |
| --- | --- |
| `oh-my-posh config export --output -` | 导出当前生效配置，排查主题读取 |
| `oh-my-posh print preview` | 预览提示符渲染 |

主题文件：`../../config/oh-my-posh/anywhere.omp.json`，Catppuccin 风格，与 yazi / helix 配色呼应。需要 Windows Terminal 配置 Nerd Font，否则图标显示为豆腐块。

## 目录跳转与别名

- `z` / `zi`：见 `zoxide.md`。
- `ll` / `la` / `lt` / `lg` 等：见 `eza.md`，由 `config/eza/aliases.ps1` 提供，`profile.ps1` 会加载它。

## yazi wrapper（y / yg / gw）

与 Unix `env.sh` 的三个 wrapper 对齐，定义在 `../../config/shell/profile.ps1`，依赖的工具存在才会定义（装完工具需重开终端）：

| 命令 | 作用 |
| --- | --- |
| `y [yazi 参数]` | 启动 yazi，退出后自动 `cd` 到浏览目录；按 `Q`（`quit --no-cwd-file`）退出则不切换 |
| `yg [yazi 参数]` | 在 yazi 里选文件（`--chooser-file`），退出后按终端宽度用 glow 精读 |
| `gw [glow 参数]` | 按当前终端宽度渲染 glow，绕开 v3 的 120 列上限 |

实现差异：Unix 的 `tput cols` 换为 `[Console]::WindowWidth`（失败时回退 `$Host.UI.RawUI.WindowSize.Width`，再失败取 0）；`GLOW_WIDTH` 仅在调用期间临时设置，结束后恢复原值。临时文件用 GUID 命名并总是清理，避免多会话并发冲突。

**起始目录（Windows 特有陷阱）**：PowerShell 的 `Set-Location`/`cd` 只改 PS 的 provider location，**不同步进程原生 cwd**（`[Directory]::GetCurrentDirectory()` 仍是 shell 启动目录）。原生 exe（yazi）继承的是后者，所以若直接 `yazi --cwd-file=...` 不传路径，yazi 会从 shell 最初的启动目录开始，而不是你 `cd` 到的目录——表现为「按 `y` 总是进入固定目录」。Unix bash 的 `cd` 会调 `chdir()`，两者一致，故无此问题。修复：`y` / `yg` 在无显式参数时把 `(Get-Location).ProviderPath` 作为 ENTRY 参数显式传给 yazi（`yazi <path> --cwd-file=...`），有显式参数则尊重它。
