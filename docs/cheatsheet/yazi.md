# yazi

配置源文件：`../../config/yazi/{yazi,keymap,theme}.toml`、`../../config/yazi/init.lua`、`../../config/yazi/plugins/`。

基础：

| 命令 | 作用 |
| --- | --- |
| `yazi` | 从当前目录启动 |
| `yazi /path/to/dir` | 从指定目录启动 |
| `yazi file.txt` | 启动并定位到文件 |

## 导航（默认键位）

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

## 选择与文件操作

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

## 查找与视图

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

| 按键 | 作用 | 平台 |
| --- | --- | --- |
| `g h` | 跳转到家目录 | 全平台 |
| `g d` | 跳转到下载目录（Windows 为 `%USERPROFILE%\Downloads`，Unix 为 `~/Downloads`） | 全平台 |
| `g c` | 跳转到配置目录（Windows 为 `%USERPROFILE%\anywhere`，Unix 为 `~/.config`） | 全平台 |
| `g f` | 平铺展开视图（fd 引擎，最多 3 层；依赖 fd） | 仅 Unix（`for = "unix"`） |
| `g i` | 拉起 lazygit（暂存 / 提交 / diff / stash；依赖 lazygit） | 仅 Unix（`for = "unix"`） |
| `g v` | 列出 Git 变更文件（`vcs-files.yazi` 插件的 `vcs://` 虚拟视图） | 仅 Unix（`for = "unix"`） |
| `z` | 模糊搜索（内置 fzf 插件，候选源为 fd；依赖 fzf 二进制） | 全平台（需 fzf） |

> markdown 文件预览由 glow 插件渲染（目录由 eza 插件树状预览）；`o` 用 glow 精读，`O` 交互选择 glow / hx / edit。shell 侧另有 `y`（退出 yazi 后 cd 到浏览目录）、`yg`（选文件后 glow 精读）、`gw`（按 pane 宽度渲染）三个 wrapper，见 `../../config/shell/env.sh`。`g f` / `g i` / `g v` 在 `keymap.toml` 中声明为 `for = "unix"`，win11 不会生效；`z` 依赖 fzf 二进制，而 win11 的 `install.ps1` 未安装 fzf，需自行补装。
