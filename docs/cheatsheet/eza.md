# eza

配置源文件：`../../config/eza/aliases.ps1`（PowerShell）与 `../../config/eza/aliases.sh`（bash / zsh）。PowerShell 默认不覆盖内置 `ls`，需要时取消 `aliases.ps1` 末行的注释。

常用别名（平台差异见表下注释）：

| 别名 | 等价命令 |
| --- | --- |
| `ls` | `eza --color=always --icons --group-directories-first` |
| `ll` | `eza -la --git --header`（linux-fedora 实测，无 `--icons`） |
| `la` | `eza -a --color=always --icons --group-directories-first` |
| `lt` | `eza --tree --level=2 --git-ignore`（linux-fedora 实测） |
| `lg` | `eza -la --git --header --sort=modified`（linux-fedora 实测） |
| `lss` | `eza -l --color=always --icons --time-style=long-iso` |

> win11 的 `aliases.ps1` 提供 `l` / `ll` / `la` / `lt` / `ltree` / `lg` / `lss` 等函数与别名；上表中的 Unix 实测写法来自 `aliases.sh`，两者细节不同，具体以源文件为准。

常用参数：

| 参数 | 作用 |
| --- | --- |
| `-a`, `--all` | 显示隐藏文件 |
| `-l`, `--long` | 长格式 |
| `-h`, `--header` | 显示表头 |
| `-T`, `--tree` | 树状显示 |
| `-L N`, `--level=N` | 限制树深度 |
| `--icons [when]` | 显示 Nerd Font 图标（`always` / `auto` / `never`） |
| `--git` | 显示 Git 状态（仅当前目录） |
| `--git-all` | 递归显示 Git 状态 |
| `-d`, `--group-directories-first` | 目录排在文件前 |
| `-s NAME`, `--sort=NAME` | 排序：`name` / `size` / `date` / `extension` / `type` |
| `-r`, `--reverse` | 反转排序 |
| `--time-style=STYLE` | `date` / `iso` / `long-iso` / `full-iso` / `relative` |
| `-F`, `--classify` | 在名称后追加类型标记 |
| `--color=WHEN` | `always` / `auto` / `never` |

示例：

```bash
eza --tree --level=3 --icons --git-ignore
ll .git
eza -l --sort=date --reverse
```

> 预览插件在非 TTY 场景必须显式加 `--color=always`，否则 eza 自动关闭颜色。
