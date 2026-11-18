-- anywhere: directory preview rendered by eza
-- Target yazi: 26.9.1 (Lua previewer API, adapted from glow.yazi/main.lua)
--
-- Non-obvious points:
--   1. eza disables colors when stdout is NOT a tty, so --color=always is required.
--   2. Tree depth is fixed by --level; deeper entries are simply not shown
--      (scrolling cannot reveal them). Tune TREE_LEVEL to taste.
--   3. --git runs `git status` per preview; in huge repos this can be slow.
--      Remove "--git" from EZA_ARGS if previews lag.
--   4. Icons need a Nerd Font terminal; disabled by default to avoid tofu
--      boxes. Append "--icons=always" to EZA_ARGS to enable.

local M = {}

local TREE_LEVEL = 2
local EZA_ARGS = {
  "-a",
  "--tree",
  "--level=" .. TREE_LEVEL,
  "--git",
  "--color=always",
  "--group-directories-first",
}

function M:peek(job)
  -- job.file.path is a Url userdata in yazi 26.x; it must be tostring()'ed
  -- before being passed to Command:arg() (glow.yazi does this inside quote()).
  local args = { table.unpack(EZA_ARGS) }
  table.insert(args, "--")
  table.insert(args, tostring(job.file.path))

  local child = Command("eza")
    :arg(args)
    :stdout(Command.PIPED)
    :stderr(Command.PIPED)
    :spawn()

  -- eza missing / failed to spawn: fall back to yazi's built-in folder previewer
  if not child then
    return require("folder"):peek(job)
  end

  local opt = { ansi = true, tab_size = rt.preview.tab_size, wrap = rt.preview.wrap, width = job.area.w }
  local limit = job.area.h
  local i, lines = 0, {}
  repeat
    local next, event = child:read_line()
    if event == 1 then
      return require("folder"):peek(job)
    elseif event ~= 0 then
      break
    end

    local wrapped = ui.lines(next, opt)
    local from = math.max(1, job.skip - i + 1)
    local to = math.min(#wrapped, job.skip + limit - i)

    i = i + #wrapped
    for j = from, to do
      lines[#lines + 1] = wrapped[j]
    end
  until i >= job.skip + limit

  child:start_kill()
  if job.skip > 0 and i < job.skip + limit then
    ya.emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
  else
    ya.preview_widget(job, ui.Text(lines):area(job.area))
  end
end

function M:seek(job) require("code"):seek(job) end

return M
