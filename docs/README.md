# docs 目录说明

本目录存放工具链的**说明与对照**，不含实际配置源（在 `config/`）和安装脚本（在 `scripts/`）。

| 文件 | 职责 |
| --- | --- |
| `win11-toolchain.md` | Windows 11 工具链指南：前置说明、工具与功能、安装/配置/验证流程 |
| `linux-fedora-toolchain.md` | Fedora / RHEL 系工具链指南，TencentOS 实测 |
| `toolchain.yaml` | 跨平台工具/功能对照，仅对齐各平台指南的「工具与功能」清单 |
| `cheatsheet/` | 按工具拆分的命令速查，见 `cheatsheet/README.md` |
| `tui-workflow-gaps.md` | 现代 TUI 工作流缺口分析（分析记录，未实施） |

## 各文件关系

- **平台指南**（`*-toolchain.md`）是操作入口：说明本平台装什么、怎么装、怎么验证。
- **`toolchain.yaml`** 只做对照：把各平台的工具与功能列在一起，数据取自平台指南的「工具与功能」小节。要改工具清单，先改平台指南，再同步到这里。
- **`cheatsheet/`** 只收录命令与按键，不重复安装步骤；安装步骤以平台指南为准。
- **`tui-workflow-gaps.md`** 是阶段性分析记录，只描述缺口与优先级，不含实施方案。

## 章节结构

两份平台指南结构相同：

| 文档 | 章节 |
| --- | --- |
| `win11-toolchain.md` | 1. 前置说明 / 2. 工具与功能 / 3. 安装、配置与验证 |
| `linux-fedora-toolchain.md` | 1. 前置说明 / 2. 工具与功能 / 3. 安装、配置与验证 |

第 3 节下分「前置准备」与「工具链」，工具链内按 安装 / 配置链接 / 验证 / 排错 展开。

`toolchain.yaml` 的 `platforms.<平台>.tools` 与 `functions` 取自各指南的「工具与功能」清单（均为第 2 节）；安装/配置脚本对应「安装、配置与验证」节，不在 YAML 中重复。
