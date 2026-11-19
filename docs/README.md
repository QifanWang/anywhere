# docs 目录说明

本目录存放工具链的**说明与对照**，不含实际配置源（在 `config/`）和安装脚本（在 `scripts/`）。

| 文件 | 职责 |
| --- | --- |
| `win11-toolchain.md` | Windows 11 工具链指南：前置说明、工具与功能、安装/配置/验证流程 |
| `linux-fedora-toolchain.md` | Fedora / RHEL 系工具链指南，TencentOS 实测 |
| `toolchain.yaml` | 跨平台工具/功能对照，仅对齐各平台指南的「工具与功能」清单 |
| `cheatsheet/` | 按工具拆分的命令速查，见 `cheatsheet/README.md` |

## 各文件关系

- **平台指南**（`*-toolchain.md`）是操作入口：说明本平台装什么、怎么装、怎么验证。
- **`toolchain.yaml`** 只做对照：把各平台的工具与功能列在一起，数据取自平台指南的「工具与功能」小节。要改工具清单，先改平台指南，再同步到这里。
- **`cheatsheet/`** 只收录命令与按键，不重复安装步骤；安装步骤以平台指南为准。

## 章节结构

两份平台指南结构目前不同：

| 文档 | 章节 |
| --- | --- |
| `win11-toolchain.md` | 1. 前置说明 / 2. 工具与功能 / 3. 安装、配置与验证 |
| `linux-fedora-toolchain.md` | 1. 包管理器 / 2. 终端与 Shell / 3. 工具与功能 / 4. 安装、配置与验证 |

`toolchain.yaml` 的 `platforms.<平台>.tools` 与 `functions` 取自各指南的「工具与功能」清单（win11 为第 2 节，linux-fedora 为第 3 节）；安装/配置脚本对应「安装、配置与验证」节，不在 YAML 中重复。
