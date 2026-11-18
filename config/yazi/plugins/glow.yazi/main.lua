-- anywhere: markdown preview rendered by glow
-- Target yazi: 26.9.1 (Lua previewer API, adapted from built-in json.lua)
--
-- Two non-obvious points:
--   1. glow v3 outputs nothing when stdout is NOT a tty and a FILE argument is used.
--      It only renders via stdin, so we must run: glow ... - < 'file'  (hence sh -c).
--   2. `-w 0` renders an empty string; width is clamped to >= 20.
--   3. `-s dark` forces a colored style, bypassing glow's `notty` auto-style for pipes.
--      Change to `-s light` if you use a light terminal theme.
--   4. glow emits OSC 8 hyperlink sequences terminated by BEL (\a, 0x07); yazi's
--      ANSI parser doesn't understand OSC 8 and renders the leftover BEL as "^G"
--      (visible at long-link line wraps). Strip the whole sequence via sed —
--      the link text is kept and was never clickable in the preview anyway.

local M = {}

-- Shell single-quote escaping for arbitrary file paths.
local function quote(path)
  local escaped = tostring(path):gsub("'", "'\\''")
  return "'" .. escaped .. "'"
end

function M:peek(job)
  local width = math.max(20, job.area.w - 2)
  -- \27 = ESC, \7 = BEL (raw bytes fed to sed so sh -c needs no extra quoting)
  local cmd = string.format(
    "glow -s dark -w %d - < %s | sed -E 's/\27]8;[^\7]*\7//g; s/\7//g'",
    width, quote(job.file.path))

  local child = Command("sh")
    :arg({ "-c", cmd })
    :stdout(Command.PIPED)
    :stderr(Command.PIPED)
    :spawn()

  -- glow missing / failed to spawn: fall back to yazi's built-in code previewer
  if not child then
    return require("code"):peek(job)
  end

  local opt = { ansi = true, tab_size = rt.preview.tab_size, wrap = rt.preview.wrap, width = job.area.w }
  local limit = job.area.h
  local i, lines = 0, {}
  repeat
    local next, event = child:read_line()
    if event == 1 then
      return require("code"):peek(job)
    elseif event ~= 0 then
      break
    end

    local wrapped = ui.lines(next, opt)
    local from = math.max(1, job.skip - i + 1)
    local to = math.min(#wrapped, job.skip + limit - i)

    i = i + #wrapped
    for j = from, to do
      lines[#lines + 1] = M.normalize_bg(wrapped[j])
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

-- Unify glow's per-line background fill with yazi's theme background.
function M.normalize_bg(line)
  local bg = th.app.overall:bg()
  if bg then
    return line:map(function(span) return span:bg(bg) end)
  else
    return line
  end
end

return M
