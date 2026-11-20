# tmux（非 win11 平台）

win11 使用 [RMUX](rmux.md)，不使用 tmux。本页适用于 Linux / WSL 等平台；配置源文件为 `../../config/tmux/tmux.conf`。

本仓库配置保持出厂默认前缀键 `C-b`。下文 `C-b` 表示先按 `Ctrl+B`，松开后再按后续键。

## 会话

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

## 窗口与面板（前缀键操作）

| 按键 | 作用 |
| --- | --- |
| `C-b c` | 新建窗口 |
| `C-b ,` | 重命名当前窗口 |
| `C-b n` / `C-b p` | 下一个 / 上一个窗口 |
| `C-b 0`..`9` | 跳到指定编号窗口 |
| `C-b w` | 窗口列表 |
| `C-b %` | 左右分屏（保持当前路径） |
| `C-b "` | 上下分屏（保持当前路径） |
| `C-b 方向键` | 在面板间移动 |
| `C-b z` | 最大化/还原当前面板 |
| `C-b x` | 关闭当前面板 |
| `C-b q` | 显示面板编号 |
| `C-b ?` | 查看全部快捷键 |

> 本仓库 tmux 配置为极简风格（linux-fedora 实测）：未绑定 `|` / `-` 分屏与 hjkl 移动，使用 tmux 默认键位；未绑定重载键，改配置后执行 `tmux source-file ~/.tmux.conf`。

## 复制模式（emacs 风格，tmux 默认）

| 按键 | 作用 |
| --- | --- |
| `C-b [` | 进入复制模式 |
| 方向键 | 移动光标 |
| `C-s` / `C-r` | 向下 / 向上搜索 |
| `C-space` | 开始选择 |
| `Alt-w` | 复制选中内容 |
| `C-b ]` | 粘贴 |
| `q` / `Esc` | 退出复制模式 |

> linux-fedora 实测为 tmux 2.7：`mode-keys emacs`，搜索用 `C-s` / `C-r`；且 tmux < 3.1 不认 XDG 路径，`scripts/linux-fedora/bootstrap.sh` 会改链单文件 `~/.tmux.conf`。
