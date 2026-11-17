# 命令 Cheatsheet

跨平台通用速查表。平台专属的安装与差异说明见 `win11/INSTALL.md`、`mac/INSTALL.md`、`linux-fedora/INSTALL.md`；配置源文件在 `../config/`，按工具分目录，适用平台写在各文件头部。

> **win11 不使用 tmux**，改用 RMUX，见 `win11/CHEATSHEET.md`。下面的 tmux 章节适用于其他平台。

## tmux（非 win11 平台）

本仓库配置保持出厂默认前缀键 `C-b`。下文 `C-b` 表示先按 `Ctrl+B`，松开后再按后续键。

### 会话

| 命令 | 作用 |
| --- | --- |
| `tmux` | 新建匿名会话 |
| `tmux new -s dev` | 新建名为 `dev` 的会话 |
| `tmux ls` | 列出会话 |
| `tmux a -t dev` | 接入 `dev` 会话 |
| `tmux detach` / `C-b d` | 离开当前会话（保持运行） |
| `tmux rename-session -t dev work` | 重命名会话 |
| `tmux kill-session -t dev` | 结束指定会话 |
| `tmux kill-server` | 结束所有会话 |
| `tmux attach -t dev -d` | 在其他终端接管并踢掉原有连接 |

### 窗口与面板（前缀键操作）

| 按键 | 作用 |
| --- | --- |
| `C-b c` | 新建窗口 |
| `C-b ,` | 重命名当前窗口 |
| `C-b n` / `C-b p` | 下一个 / 上一个窗口 |
| `C-b 0`..`9` | 跳到指定编号窗口 |
| `C-b w` | 窗口列表 |
| `C-b \|` | 左右分屏（保持当前路径） |
| `C-b -` | 上下分屏（保持当前路径） |
| `C-b h/j/k/l` | 在面板间移动 |
| `C-b H/J/K/L` | 调整面板大小（可连按） |
| `C-b z` | 最大化/还原当前面板 |
| `C-b x` | 关闭当前面板 |
| `C-b q` | 显示面板编号 |
| `C-b r` | 重载配置文件 |
| `C-b ?` | 查看全部快捷键 |

### 复制模式（vi 风格）

| 按键 | 作用 |
| --- | --- |
| `C-b [` | 进入复制模式 |
| `h/j/k/l` | 移动光标 |
| `v` | 开始选择 |
| `y` | 复制选中内容 |
| `C-b ]` | 粘贴 |
| `q` / `Esc` | 退出复制模式 |

---

## eza

常用别名（由 `../config/eza/aliases.ps1` 或 `../config/eza/aliases.sh` 提供；PowerShell 默认不覆盖内置 `ls`，需要时取消 `aliases.ps1` 末行的注释）：

| 别名 | 等价命令 |
| --- | --- |
| `ls` | `eza --color=always --icons --group-directories-first` |
| `ll` | `eza -lah --color=always --icons --group-directories-first --git` |
| `la` | `eza -a --color=always --icons --group-directories-first` |
| `lt` | `eza --tree --level=2 --color=always --icons` |
| `lg` | `eza -lah --color=always --icons --group-directories-first --git` |
| `lss` | `eza -l --color=always --icons --time-style=long-iso` |

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

---

## glow

| 命令 | 作用 |
| --- | --- |
| `glow README.md` | 渲染指定文件 |
| `glow -p README.md` | 使用系统 Pager 查看长文档 |
| `glow -w 80 README.md` | 指定换行宽度 |
| `glow -s dark README.md` | 指定样式：`auto` / `dark` / `light` / 自定义 JSON |
| `glow -a .` | 包含隐藏文件与 `.gitignore` 中的文件 |
| `glow .` | 在目录中打开交互式 TUI |
| `glow` | 从当前目录开始浏览 Markdown |
| `glow -` | 从标准输入读取 |
| `glow config` | 用 `$EDITOR` 打开配置文件 |

管道用法：

```bash
curl -sL https://example.com/README.md | glow -
git log --oneline | glow -
```

交互式 TUI 按键：

| 按键 | 作用 |
| --- | --- |
| `↑` / `↓`、`j` / `k` | 上下移动 |
| `Enter` | 打开文档 |
| `Esc` | 返回上一层 |
| `/` | 搜索 |
| `?` | 帮助 |
| `q` / `Ctrl+C` | 退出 |

---

## yazi

基础：

| 命令 | 作用 |
| --- | --- |
| `yazi` | 从当前目录启动 |
| `yazi /path/to/dir` | 从指定目录启动 |
| `yazi file.txt` | 启动并定位到文件 |

### 导航（默认键位）

| 按键 | 作用 |
| --- | --- |
| `j` / `k`、`↓` / `↑` | 下 / 上移动 |
| `l` / `→`、`Enter` | 进入目录或打开文件 |
| `h` / `←` | 返回上级目录 |
| `H` / `L` | 历史后退 / 前进 |
| `1`..`9` | 切换标签页 |
| `[` / `]` | 上一个 / 下一个标签页 |
| `{` / `}` | 交换标签页位置 |
| `~` / `F1` | 帮助 |
| `q` | 退出 |

### 选择与文件操作

| 按键 | 作用 |
| --- | --- |
| `Space` | 切换选中并下移 |
| `Ctrl+A` | 全选 |
| `Ctrl+R` | 反选 |
| `v` / `V` | 进入 / 退出可视模式 |
| `y` | 复制（yank） |
| `x` | 剪切 |
| `p` | 粘贴 |
| `P` | 强制粘贴（覆盖） |
| `Y` / `X` | 清空复制/剪切状态 |
| `d` | 移到回收站 |
| `D` | 永久删除 |
| `r` | 重命名 |
| `a` | 新建文件 |
| `A` | 批量新建 |
| `Esc` | 取消当前操作 |

### 查找与视图

| 按键 | 作用 |
| --- | --- |
| `s` | 用 `fd` 搜索文件 |
| `S` | 用 `rg` 搜索内容 |
| `f` | 过滤当前列表（智能大小写） |
| `/` | 逐字查找并跳转 |
| `?` | 反向逐字查找 |
| `n` / `N` | 跳到下一个 / 上一个匹配 |
| `.` | 显示/隐藏隐藏文件 |
| `o` | 使用 opener 打开 |
| `O` | 选择 opener 后打开 |
| `;` | 交互执行 shell 命令 |
| `:` | 阻塞式执行 shell 命令 |

本仓库 `keymap.toml` 额外添加（以 `g` 开头的前缀键）：

| 按键 | 作用 |
| --- | --- |
| `g d` | 跳转到下载目录（Windows 为 `%USERPROFILE%\Downloads`，Unix 为 `~/Downloads`） |
| `g h` | 跳转到家目录 |
| `g c` | 跳转到配置目录（Windows 为 `%USERPROFILE%\anywhere`，Unix 为 `~/.config`） |
| `g v` | 用 `$EDITOR` / VS Code 打开选中文件 |
