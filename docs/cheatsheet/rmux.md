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

一键开命名会话（新窗口 + 左右分屏）用仓库脚本，见 `../../scripts/win11/start-rmux.ps1`：

```powershell
.\scripts\win11\start-rmux.ps1 -Name work          # 新窗口、左右分屏、命名 work
.\scripts\win11\start-rmux.ps1 -Name dev -NoWindow  # 不开新窗口，当前终端 attach
```

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
| `C-b T` | 切换面板鼠标模式（默认开启；临时关掉可恢复终端原生选择） |
| `C-b r` | 重载 `rmux.conf` |
| `C-b PPage` | 进入复制模式并向上翻页（滚动历史） |
| `C-b ?` | 查看全部键位 |

### 滚动面板历史

开多个 panel 后要看某块历史输出，有两种方式：

- **鼠标滚轮**：默认 `mouse on`，直接在目标面板上滚轮即可滚动；点击面板可切换焦点，拖拽边界可调整大小。需要终端原生选择（双击选词、拖选复制）时按 `C-b T` 临时关掉鼠标，完事再按一次切回。
- **键盘**：按 `C-b PPage` 或 `C-b [` 进入复制模式，再用 `↑`/`↓`、`PgUp`/`PgDn`、`j`/`k` 滚动，`Esc`/`q` 退出。注意普通模式下裸 `↑`/`↓` 是发给 shell 翻命令历史的，`C-b ↑/↓` 是切换面板，都不是滚动内容。

## 复制模式

| 按键 | 作用 |
| --- | --- |
| `C-b [` | 进入 vi 复制模式 |
| `↑`/`↓`、`j`/`k` | 上 / 下滚动一行 |
| `PgUp`/`PgDn`、`Space` | 上 / 下翻一页 |
| `C-b PPage` | 进入复制模式并向上翻页（可直接从普通模式按） |
| `v` | 开始选择 |
| `V` | 选择整行 |
| `C-v` | 矩形选择 |
| `y` / `C-c` | 复制并退出（经 UTF-8 `copy-command` 写入 Windows 剪贴板） |
| `C-b ]` | 粘贴 |
| `Esc` / `q` | 退出复制模式 |

进入复制模式后，状态栏左侧会出现反色的 ` COPY ` 标记（本仓库在 `status-left` 里用 `#{?pane_in_mode,...}` 实现），避免误进后没察觉——尤其在 codebuddy 这类 TUI 里，vi 复制模式的 `g` 是 `history-top`（跳到历史开头），会拦截本要输入程序的 `g` 键。看到 ` COPY ` 就按 `q` / `Esc` 退出再继续操作。

## 与 tmux 的差异提示

- 原生 Windows 实现（ConPTY + 命名管道），不依赖 WSL 或 MSYS2。
- 默认前缀 `C-b` 保持不变；出厂默认鼠标为 `off`，但本仓库改设为 `on`（多 panel 滚动所需），可用 `C-b T` 临时切回原生选择。
- 状态栏配色在配置里统一用 `status-style`（rmux 默认是绿底黑字，单独设 `status-bg` 会被它盖掉），改为 Catppuccin 深底浅字，黑屏幕下更清晰；复制模式另有反色 ` COPY ` 标记。
- Windows 剪贴板不能用裸 `clip.exe`，否则非 ASCII 字符乱码；本仓库使用显式的 PowerShell UTF-8 命令。
- 没有自身配置时会回退读取 tmux.conf；本仓库提供原生 `rmux.conf`，不走回退。
- 配置重载不会清除已删除的旧设置，必要时用 `set -u <option>` 显式清除。
