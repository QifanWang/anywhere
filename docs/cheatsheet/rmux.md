# RMUX 速查表（win11）

win11 使用 **RMUX**，不使用 tmux。RMUX 是原生 Windows 终端复用器，CLI 与配置语法兼容 tmux。完整命令可用 `rmux list-commands` 查看，本文只列常用项。

配置源文件：`../../config/rmux/rmux.conf`。安装与配置链接见 `../win11-toolchain.md`。

## CLI

| 命令 | 作用 |
| --- | --- |
| `rmux` | 启动并接入新会话 |
| `rmux new-session -s dev` | 新建并接入名为 `dev` 的会话 |
| `rmux new-session -d -s dev` | 新建分离会话 |
| `rmux list-sessions` | 列出会话 |
| `rmux attach-session -t dev` | 接入 `dev` |
| `rmux detach-client` / `C-b d` | 离开会话但保持运行 |
| `rmux kill-session -t dev` | 结束指定会话 |
| `rmux kill-server` | 结束所有会话 |
| `rmux split-window -h -t dev` | 在目标会话中左右分屏 |
| `rmux split-window -v -t dev` | 上下分屏 |
| `rmux send-keys -t dev "echo ok" Enter` | 向目标会话发送按键 |
| `rmux capture-pane -p -t dev` | 抓取面板输出 |
| `rmux list-keys -N` | 列出当前键位 |
| `rmux list-commands` | 列出全部命令 |
| `rmux -V` | 查看版本 |

RMUX 还提供面向脚本的信号原语：

```powershell
rmux new-session -d -s ci
rmux send-keys -t ci "Write-Output 'test result: ok'; rmux wait-for -S ci-done" Enter
rmux wait-for ci-done
rmux capture-pane -p -t ci
```

## 前缀键操作

本仓库配置保持出厂默认前缀键 `C-b`。`C-b` 表示先按 `Ctrl+B`，松开后再按后续键。

| 按键 | 作用 |
| --- | --- |
| `C-b c` | 新建窗口（保持当前路径） |
| `C-b %` | 左右分屏（保持当前路径） |
| `C-b "` | 上下分屏（保持当前路径） |
| `C-b v` / `C-b b` | 左右 / 上下分屏的易输入别名 |
| `C-b h/j/k/l` | 在面板间移动 |
| `C-b H/J/K/L` | 调整面板大小（可连按） |
| `C-b Tab` | 返回上一个窗口 |
| `C-b n` / `C-b p` | 下一个 / 上一个窗口 |
| `C-b 0`..`9` | 跳到指定编号窗口 |
| `C-b z` | 最大化 / 还原当前面板 |
| `C-b x` | 关闭当前面板 |
| `C-b d` | 脱离当前会话 |
| `C-b T` | 切换面板鼠标模式（默认关闭，保留终端原生选择） |
| `C-b r` | 重载 `rmux.conf` |
| `C-b ?` | 查看全部键位 |

## 复制模式

| 按键 | 作用 |
| --- | --- |
| `C-b [` | 进入 vi 复制模式 |
| `v` | 开始选择 |
| `V` | 选择整行 |
| `C-v` | 矩形选择 |
| `y` / `C-c` | 复制并退出（经 UTF-8 `copy-command` 写入 Windows 剪贴板） |
| `C-b ]` | 粘贴 |
| `Esc` | 退出复制模式 |

## 与 tmux 的差异提示

- 原生 Windows 实现（ConPTY + 命名管道），不依赖 WSL 或 MSYS2。
- 默认前缀 `C-b` 保持不变；默认鼠标为 `off`，本仓库也保持该默认值。
- Windows 剪贴板不能用裸 `clip.exe`，否则非 ASCII 字符乱码；本仓库使用显式的 PowerShell UTF-8 命令。
- 没有自身配置时会回退读取 tmux.conf；本仓库提供原生 `rmux.conf`，不走回退。
- 配置重载不会清除已删除的旧设置，必要时用 `set -u <option>` 显式清除。
