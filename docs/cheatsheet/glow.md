# glow

配置源文件：`../../config/glow/glow.yml`。

| 命令 | 作用 |
| --- | --- |
| `glow README.md` | 渲染指定文件 |
| `glow -p README.md` | 使用系统 Pager 查看长文档 |
| `glow -w 80 README.md` | 指定换行宽度 |
| `glow -s dark README.md` | 指定样式：`auto` / `dark` / `light` / 自定义 JSON |
| `glow -a .` | 包含隐藏文件与 `.gitignore` 中的文件 |
| `glow .` | 在目录中打开交互式 TUI |
| `glow` | 从当前目录开始浏览 Markdown |
| `glow -` | 从标准输入读取 |
| `glow config` | 用 `$EDITOR` 打开配置文件 |

管道用法：

```bash
curl -sL https://example.com/README.md | glow -
git log --oneline | glow -
```

交互式 TUI 按键：

| 按键 | 作用 |
| --- | --- |
| `↑` / `↓`、`j` / `k` | 上下移动 |
| `Enter` | 打开文档 |
| `Esc` | 返回上一层 |
| `/` | 搜索 |
| `?` | 帮助 |
| `q` / `Ctrl+C` | 退出 |

> v3 注意：`-w 0` 输出为空（自适应只在配置文件 `width: 0` 生效，且有 120 列硬上限）；预览插件应通过 stdin 读取（`glow - < file`），避免非 TTY + 文件参数输出为空。详见 `../toolchain.yaml`。
