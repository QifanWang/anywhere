# 现代 TUI 工作流缺口分析

> 状态：**分析记录，未实施**。基于 2026-11 仓库现状；只记录缺口，不含改动方案。

## 结论

单点工具（终端复用 / 文件管理 / 查找 / Git / 编辑 / Markdown 阅读）已配齐。缺的不是再装一个工具，而是三层：**shell 交互层**、**Windows 侧同等体验**、**工具链生命周期管理**。

## 1. Shell 交互层：整套缺席（最大缺口）

文档已两处承认：

- `docs/win11-toolchain.md:39`：`Shell 的历史命令与智能提示**当前不配置**`
- `docs/linux-fedora-toolchain.md:43-44`：历史命令 / 智能提示均为「当前不配置」

全仓库搜索 `zoxide` / `atuin` / `starship` / `PSReadLine` / `autosuggestions` 零命中。当前 shell 侧只有 `config/shell/env.sh:21-43` 的三个 wrapper 与两个 FZF 变量：

- `y`：退出 yazi 后 `cd` 到浏览目录
- `yg`：选文件后 glow 精读
- `gw`：按 pane 宽度渲染

容易误判的是 `z`：`config/yazi/keymap.toml` 的 `z` 是 yazi **内部模糊搜文件**，不是 zoxide 那种按访问频率跳目录；两者不重叠。

所有 TUI 都会「退回 shell」（yazi 的 `;` / `:`、tmux 新 pane、helix `:!`），shell 本身是短板放大器。通常补三件：

| 类别 | 工具 | 与现状的关系 |
| --- | --- | --- |
| 目录跳转 | `zoxide` | `z proj` 直达，与 `y`（浏览式进入）互补 |
| 历史检索 | `atuin` | 跨会话检索，替掉 `history | grep` |
| 提示符与提示 | `starship` + `zsh-autosuggestions` / `zsh-syntax-highlighting`；Windows 侧 `PSReadLine` 预测/历史搜索 + `oh-my-posh` | 当前两平台均无配置 |

Windows 侧另有具体断点：`$PROFILE` 的别名加载靠手工改（`docs/win11-toolchain.md` §3.2），而 `scripts/win11/verify.ps1:72-78` 只检查 `ll` 是否存在，不检查 profile 是否被正确加载。

## 2. Windows 侧工作流残缺

`docs/toolchain.yaml:60-63` 已写明：

```yaml
- role: Shell wrapper
  win11: 未配置
  linux: y / yg / gw
```

三处断点：

1. `config/yazi/keymap.toml:56-72` 的 `g f` / `g i` / `g v` 全部 `for = "unix"` → Windows 文件管理器里没有 lazygit 入口、没有变更文件视图。
2. 共用配置里写死了 `tmux`：`config/helix/config.toml:39` 的 `yank = { command = "tmux", args = ["show-buffer"] }`，而 Windows 复用器命令是 `rmux`（`config/rmux/rmux.conf`）。在 Windows 上这条粘贴链很可能不通——这是「同一工具配置尽量共用一份」约定的隐藏漏洞。
3. yazi 的 Windows opener 落到 `code %s`（`config/yazi/yazi.toml:78`），但 `scripts/win11/install.ps1:50-59` 的安装计划只有 8 个工具、不含 VS Code，`O` 菜单里的「Edit in VS Code」可能打不开。

## 3. 查看/观测类工具缺位（按场景补，非必需）

- `btop`、`dust` / `dua`：SSH 服务器场景下看系统状态与磁盘占用，当前没有。
- `bat`、`delta`：yazi 预览只定制了 md(glow) 与目录(eza)（`config/yazi/yazi.toml:39-44`），其余文本走内置；命令行 git diff 也没有专门渲染器。
- `tldr`：速查目前是静态 md，没有交互式命令查询入口。

## 4. 工程化与生命周期

- **没有单一版本源**：`scripts/linux-fedora/install.sh:22-25` 硬编码版本，`docs/toolchain.yaml` 再写一遍，`scripts/win11/install.ps1` 交给 winget 自动升最新。升级要「改脚本 + 同步文档」，已经漂移：`docs/cheatsheet/yazi.md:75` 仍写「win11 的 `install.ps1` 未安装 fzf」，但脚本第 57 行明确装了。
- **没有 update / uninstall / doctor**：Linux 是「已装就跳过，升级要改版本号并先删旧二进制」（`install.sh:14`），Windows 只会升不会回滚，两边都没有反向操作。
- **shell 集成不幂等**：两个 `bootstrap` 都只打印「请手动加这两行」（`scripts/linux-fedora/bootstrap.sh:65-68`），不写入 rc / `$PROFILE`；装完靠 `verify` 才发现漏了。
- **没有静态校验**：TOML / Lua / YAML 语法、`toolchain.yaml` 与脚本版本一致性、链接目标存在性，全靠人工与目标机上的 `verify`。
- **macOS 只有占位 README**（`scripts/mac/README.md`），但多个 config 文件头写「macOS 可用」——声称支持而无落地脚本。

## 5. 会话层（刻意选择，可不动）

`config/tmux/tmux.conf:6-8` 开头声明「刻意保持极简」，没有 TPM / resurrect / 与 helix 联动的窗格导航。属于设计取舍而非遗漏，除非需要会话断电恢复。

## 优先级

| 优先级 | 内容 |
| --- | --- |
| P0 | shell 三件套（zoxide / atuin / 提示符与提示）；Windows 工作流对齐（wrapper / 剪贴板 / profile 自动化） |
| P1 | `btop` / `dust` 等观测工具 |
| P2 | 版本单一源、update / uninstall、bootstrap 幂等写入、静态校验、macOS 落地 |
