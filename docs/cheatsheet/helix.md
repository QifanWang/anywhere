# helix（hx）

配置源文件：`../../config/helix/config.toml`。linux-fedora 会安装 `hx` 并把配置链接到 `~/.config/helix`；win11 的 `bootstrap.ps1` 也链接这份配置，但 `install.ps1` 不安装 helix，需要单独安装并加入 PATH。

| 按键 | 作用 |
| --- | --- |
| `i` / `Esc` | 进入 / 退出插入模式 |
| `w` / `e` / `b` | 按 word 向后 / 向词尾 / 向前移动 |
| `x` / `d` | 删字符 / 删选择（选区朝向自动） |
| `v` / `V` | 进入字符 / 行选择 |
| `y` / `p` | 复制（同步系统剪贴板）/ 粘贴选择 |
| `u` / `U` | 撤销 / 重做 |
| `:w` / `:q` | 保存 / 退出（`wq` 保存退出） |
| `space f` / `space s` | 文件选择器 / 全工程符号搜索 |

> 剪贴板方案（ssh 远程）：yank 时发 OSC 52（由本地终端写入本机剪贴板）+ 写 tmux buffer；paste 读 tmux buffer。详见 `../../config/helix/config.toml` 注释。linux-fedora 在 glibc 2.28 上必须源码编译，见 `../linux-fedora-toolchain.md` 第 4.1 节。
