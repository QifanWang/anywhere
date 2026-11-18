-- anywhere / yazi 26.9.1 init.lua
-- 位置：~/.config/yazi/init.lua
--
-- git.yazi 插件（ya pkg add yazi-rs/plugins:git）的 setup：
-- 在文件列表 linemode 末尾追加 git 状态角标（文件名右侧）。
-- 依赖 ~/.config/yazi/plugins/git.yazi/ + yazi.toml 的 prepend_fetchers + theme.toml [git] 段。
-- order = 1500：排在其它 linemode 组件之后（size/perm 等），避免挤占文件名。
-- 关闭角标：注释掉本文件 + 删掉 yazi.toml 两条 prepend_fetchers 即可。
require("git"):setup {
	order = 1500,
}
