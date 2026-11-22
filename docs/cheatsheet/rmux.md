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

在当前 rmux 会话内一键新建**命名 window + 左右分屏**（默认不另开终端窗口），见 `../../scripts/win11/start-rmux.ps1`：

```powershell
.\scripts\win11\start-rmux.ps1 -Name work                       # 新 window 名 work、左右分屏，切过去
.\scripts\win11\start-rmux.ps1 -Name demo -Directory D:\proj     # 指定起始目录
.\scripts\win11\start-rmux.ps1 -Name demo -NewTerminalWindow     # 另开 Windows Terminal 窗口接入
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

## 复制模式（vi 风格，`mode-keys vi`）

进入后按键不再透传给程序，而是由 rmux 解释成浏览 / 搜索 / 选区 / 复制；退出后才恢复。当前 pane 是否处于该模式可用 `rmux display-message -p '#{pane_mode}'` 查看（空 = 普通，`copy-mode` = 复制模式）。

### 进入

| 方式 | 按键 / 操作 | 说明 |
| --- | --- | --- |
| 主动 | `C-b [` | 进入 vi 复制模式 |
| 主动 | `C-b PPage` | 进入并向上翻一页（内置 `copy-mode -u`） |
| 被动 | 鼠标在面板内容区**拖拽** | `MouseDrag1Pane → copy-mode -M`，复制模式常见误入途径 |
| 被动 | 点击 / 拖动滚动条 | `MouseDown1ScrollbarUp → copy-mode -u` |
| 被动 | 右键菜单 "Go To Top / Bottom" | — |

> 被动进入是 `mouse on` 的副作用，且**不会自动退出**——这是误进后 `g` 被拦截的主因。

### 退出

| 按键 | 作用 |
| --- | --- |
| `q` / `Esc` | 退出复制模式（`send-keys -X cancel`），按键恢复透传 |

进入后状态栏左侧出现反色 ` COPY ` 标记（本仓库在 `status-left` 用 `#{?pane_in_mode,...}` 实现）。在 codebuddy 这类 TUI 里看到它，按 `q`/`Esc` 退出即可恢复输入。

### 操作

**移动**

| 按键 | 作用 |
| --- | --- |
| `↑`/`↓`、`k`/`j` | 上 / 下移动一行 |
| `←`/`→`、`h`/`l` | 左 / 右移动一列 |
| `PgUp`/`PgDn` | 上 / 下翻一页 |
| `C-u` / `C-d` | 上 / 下半页 |
| `0` / `$`（`Home`/`End`） | 行首 / 行尾 |
| `^` | 行内首个非空白字符 |
| `w` / `b` / `e` | 下一个词 / 上一个词 / 词尾 |
| `H` / `M` / `L` | 屏顶 / 屏中 / 屏底 |
| `{` / `}` | 上一段 / 下一段 |

**跳转**

| 按键 | 作用 |
| --- | --- |
| `g` / `G` | 跳到历史顶部 / 底部（⚠️ vi 模式 `g` = `history-top`，会拦截想输入程序的 `g`） |
| `f`/`F`/`t`/`T` | 向后 / 向前跳到指定字符（含 / 不含） |
| `;` / `,` | 重复 / 反向重复上一个字符跳转 |
| `:` | 跳到指定行号 |

**搜索**

| 按键 | 作用 |
| --- | --- |
| `/` / `?` | 向下 / 向上搜索（弹输入框） |
| `n` / `N` | 重复上一个搜索（同向 / 反向） |
| `#` / `*` | 搜索光标下的词（反向 / 正向） |

**选区与复制**

| 按键 | 作用 |
| --- | --- |
| `v` / `Space` | 开始选择（vi 模式 `Space` 也是选区起点，不是翻页） |
| `V` | 选择整行 |
| `C-v` | 矩形选择 |
| `o` | 跳到选区另一端 |
| `y` / `C-c` / `Enter` | 复制并退出（经 UTF-8 `copy-command` 写入 Windows 剪贴板） |
| `C-b ]` | 粘贴（普通模式下也可） |

**鼠标（复制模式内）**：滚轮滚动历史；拖拽选区，松开即复制；双击选词、三击选行并复制。

## 与 tmux 的差异提示

- 原生 Windows 实现（ConPTY + 命名管道），不依赖 WSL 或 MSYS2。
- 默认前缀 `C-b` 保持不变；出厂默认鼠标为 `off`，但本仓库改设为 `on`（多 panel 滚动所需），可用 `C-b T` 临时切回原生选择。
- 状态栏配色在配置里统一用 `status-style`（rmux 默认是绿底黑字，单独设 `status-bg` 会被它盖掉），改为 Catppuccin 深底浅字，黑屏幕下更清晰；复制模式另有反色 ` COPY ` 标记。
- Windows 剪贴板不能用裸 `clip.exe`，否则非 ASCII 字符乱码；本仓库使用显式的 PowerShell UTF-8 命令。
- 没有自身配置时会回退读取 tmux.conf；本仓库提供原生 `rmux.conf`，不走回退。
- 配置重载不会清除已删除的旧设置，必要时用 `set -u <option>` 显式清除。
