# anywhere

跨平台现代 TUI 工具的**私人配置集合**。仓库只保存配置源文件，由引导脚本链接/复制到各平台的实际配置目录。

核心约定：`config/` 不按平台分层，只按工具命名；同一工具的配置尽量共用一份，无法共用时把变体放在同一工具目录内（如 `eza/aliases.sh` 与 `eza/aliases.ps1`）。

## 快速开始

**Windows 11**（前提：已安装 PowerShell 7）

```powershell
.\scripts\win11\prepare.ps1     # 前置准备：winget 镜像源 + Windows Terminal
# 重开 PowerShell 7 终端
.\scripts\win11\install.ps1     # 安装工具链
.\scripts\win11\bootstrap.ps1   # 链接配置到 XDG/APPDATA，校验/修复 PATH
# 再新开终端
.\scripts\win11\verify.ps1      # 验证工具链
```

还需在 `$PROFILE` 中加载 eza 别名（只需一次），见 `docs/win11-toolchain.md`。

**Fedora / RHEL 系（含 TencentOS）**

```bash
bash scripts/linux-fedora/prepare.sh     # 前置准备：检查依赖
bash scripts/linux-fedora/install.sh     # 安装工具链
bash scripts/linux-fedora/bootstrap.sh   # 链接配置到 XDG
# 在 ~/.bashrc / ~/.zshrc 加载 env.sh 与 aliases.sh 后新开终端
bash scripts/linux-fedora/verify.sh      # 验证工具链
```

详见各平台指南。

## 文档

| 文档 | 用途 |
| --- | --- |
| `docs/README.md` | docs 目录说明 |
| `docs/win11-toolchain.md` | Windows 11 指南 |
| `docs/linux-fedora-toolchain.md` | Fedora / RHEL 系指南 |
| `docs/toolchain.yaml` | 跨平台工具/功能对照 |
| `docs/cheatsheet/` | 按工具拆分的命令速查 |
