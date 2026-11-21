# zoxide

更智能的 `cd`：按访问频率与最近使用排序，输入少量字符直达常用目录。

配置源文件：`../../config/shell/profile.ps1`（zoxide 的 PowerShell 初始化在此）。安装与配置链接见 `../win11-toolchain.md`。

## 命令

| 命令 | 作用 |
| --- | --- |
| `z` | 无参数时跳到最高分的目录（通常是 home） |
| `z foo` | 跳到匹配 `foo` 的最高分目录 |
| `z foo bar` | 跳到同时匹配 `foo` 和 `bar` 的目录 |
| `z foo /` | 跳到 `foo` 下的子目录 |
| `z ~/foo` | 含 `/`、`.`、`~` 时按普通 `cd` 处理 |
| `z -` | 回到上一个目录 |
| `zi` | 用 fzf 交互选择后跳转（需 fzf 在 PATH） |
| `zoxide query foo` | 只查询匹配路径，不跳转（脚本用） |
| `zoxide remove foo` | 从数据库移除某条记录 |
| `zoxide init powershell` | 输出初始化脚本，由 `profile.ps1` 调用 |

## 说明

- zoxide 会**接管 `cd`**：每次 `cd` 都被记录，用于后续排序；原生 `cd` 的路径语义保留。
- 与 yazi 的 `z` 键不是一回事：yazi 的 `z` 是文件模糊搜索，zoxide 的 `z` 是目录跳转。
- `zi` 复用仓库已装的 fzf（`junegunn.fzf`），无需额外依赖。
- 数据库位于用户数据目录，跨会话持久化；换机可用 `zoxide import` / `zoxide query --list` 迁移。
