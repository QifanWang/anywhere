# PowerShell shell 交互（win11）

配置源文件：`../../config/shell/profile.ps1`。安装与配置链接见 `../win11-toolchain.md`；zoxide 单独见 `zoxide.md`。

`profile.ps1` 由用户 `$PROFILE` 一行 dot-source，内部按"工具存在才初始化"加载：eza 别名 → PSReadLine → zoxide → oh-my-posh。

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
