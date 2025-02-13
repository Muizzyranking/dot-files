---@class utils.ui
local M = {}
local api = vim.api
M.colorsheme = "habamax"

------------------------------------------------------------------------------
-- Get the color of a highlight group
---@param name string
---@return string?
------------------------------------------------------------------------------
function M.get_hl_color(name, ground)
  ground = ground or "fg"
  local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name, link = false })
    or vim.api.nvim_get_hl_by_name(name, true)
  local color = hl and (ground == "fg" and (hl.fg or hl.foreground) or (hl.fg or hl.foreground))
  local ret = ("#%06x"):format(color)
  return color and ret or " "
end

--------------------------------------------------
-- Get signs for a specific buffer and line number
---@param buf number
---@param lnum number
---@return Sign[]
--------------------------------------------------
function M.get_signs(buf, lnum)
  -- Get regular signs
  ---@type Sign[]
  local signs = {}
  -- Get extmark signs
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buf,
    -1,
    { lnum - 1, 0 },
    { lnum - 1, -1 },
    { details = true, type = "sign" }
  )
  for _, extmark in pairs(extmarks) do
    signs[#signs + 1] = {
      name = extmark[4].sign_hl_group or "",
      text = extmark[4].sign_text,
      texthl = extmark[4].sign_hl_group,
      priority = extmark[4].priority,
    }
  end

  -- Sort by priority
  table.sort(signs, function(a, b)
    return (a.priority or 0) < (b.priority or 0)
  end)

  return signs
end

--------------------------------------------------
-- Get mark for a specific buffer and line number
---@param buf number
---@param lnum number
---@return {text: string, texthl: string}|nil
--------------------------------------------------
function M.get_mark(buf, lnum)
  local marks = vim.fn.getmarklist(buf)
  vim.list_extend(marks, vim.fn.getmarklist())
  for _, mark in ipairs(marks) do
    if mark.pos[1] == buf and mark.pos[2] == lnum and mark.mark:match("[a-zA-Z]") then
      return { text = mark.mark:sub(2), texthl = "DiagnosticHint" }
    end
  end
end

--------------------------------------------------
-- Generate icon string from sign
---@param sign table|nil
---@param len number|nil
---@return string
--------------------------------------------------
function M.icon(sign, len)
  sign = sign or {}
  len = len or 2
  local text = vim.fn.strcharpart(sign.text or "", 0, len) ---@type string
  text = text .. string.rep(" ", len - vim.fn.strchars(text))
  return sign.texthl and ("%#" .. sign.texthl .. "#" .. text .. "%*") or text
end

------------------------------------------------------------
-- sets the colorscheme
---@param colorscheme string
------------------------------------------------------------
function M.set_colorscheme(colorscheme)
  local ok = pcall(function()
    vim.cmd("colorscheme " .. colorscheme)
  end)

  if ok then
    M.colorsheme = colorscheme
  else
    vim.notify("Failed to load colorscheme: " .. colorscheme, vim.log.levels.ERROR)
    vim.cmd("colorscheme habamax")
  end
  local function custom_hl()
    vim.api.nvim_set_hl(0, "WinBar", {})
    vim.api.nvim_set_hl(0, "WinBarNC", {})
  end
  custom_hl()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("WinBar Hl", { clear = true }),
    callback = custom_hl,
  })
end

------------------------------------------------------------
---Get the treesitter highlights of the passed line (no syntactic tokens)
---@param line string
---@param linenr integer 0-idx line number
---@return table<string, string>[] line_highlights
------------------------------------------------------------
local function get_ts_line_highlights(line, linenr)
  local line_hls = {}
  local ts_highlights = vim.treesitter.get_captures_at_pos

  local current_text = ""
  local previous_hl
  for i = 1, #line do
    local current_char = line:sub(i, i)
    local hl_capture = ts_highlights(0, linenr, i - 1)
    if #hl_capture < 1 then
      current_text = current_text .. current_char
    else
      local current_hl = "@" .. hl_capture[#hl_capture].capture
      if current_hl == previous_hl then
        current_text = current_text .. current_char
      else
        line_hls[#line_hls + 1] = { current_text, previous_hl }
        current_text = current_char
        previous_hl = current_hl
      end
    end
  end
  line_hls[#line_hls + 1] = { current_text, previous_hl }
  return line_hls
end

------------------------------------------------------------
---Function used to set a custom text when called by a fold action like `zc`.
---To set it check `:h v:lua-call` and `:h foldtext`.
---
---This function is **heavily** used, so we store the formatted folds in the
---`fold_cache` table to improve the performance a little.
------------------------------------------------------------
---@type table<string, { line: integer, content: string[] }>
local fold_cache = {}
function M.fold_text()
  local first_linenr, last_linenr = vim.v.foldstart, vim.v.foldend -- both 1-idx
  local first_line = vim.fn.getline(first_linenr)

  if fold_cache[first_line] and fold_cache[first_line].line == last_linenr then
    return fold_cache[first_line].content
  end

  local last_line = vim.fn.getline(last_linenr):gsub("^%s*", "")
  local lines_count = tostring(last_linenr - first_linenr)
  local filler =
    string.rep("┈", api.nvim_get_option_value("textwidth", {}) - #first_line - #last_line - #lines_count - 10)

  local fold_header_hl = get_ts_line_highlights(first_line, first_linenr - 1)
  local fold_footer_hl = get_ts_line_highlights(last_line, last_linenr - 1)

  local res = {}
  vim.list_extend(res, fold_header_hl)
  res[#res + 1] = { "  ", "Constant" }
  vim.list_extend(res, fold_footer_hl)
  res[#res + 1] = { string.format(" %s (%d)", filler, lines_count), "Constant" }

  fold_cache[first_line] = { line = last_linenr, content = res }
  return res
end

M.logo = {}
M.logo.one = [[
┈╭━━━━━━━━━━━╮┈
┈┃╭━━━╮┊╭━━━╮┃┈
╭┫┃┈▇┈┃┊┃┈▇┈┃┣╮
┃┃╰━━━╯┊╰━━━╯┃┃
╰┫╭━╮╰━━━╯╭━╮┣╯
┈┃┃┣┳┳┳┳┳┳┳┫┃┃┈
┈┃┃╰┻┻┻┻┻┻┻╯┃┃┈
┈╰━━━━━━━━━━━╯┈
=MUIZZYRANKING=

]]

M.logo.two = [[

    ███╗   ███╗██╗   ██╗██╗███████╗███████╗██╗   ██╗██████╗  █████╗ ███╗   ██╗██╗  ██╗██╗███╗   ██╗ ██████╗
    ████╗ ████║██║   ██║██║╚══███╔╝╚══███╔╝╚██╗ ██╔╝██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝██║████╗  ██║██╔════╝
    ██╔████╔██║██║   ██║██║  ███╔╝   ███╔╝  ╚████╔╝ ██████╔╝███████║██╔██╗ ██║█████╔╝ ██║██╔██╗ ██║██║  ███╗
    ██║╚██╔╝██║██║   ██║██║ ███╔╝   ███╔╝    ╚██╔╝  ██╔══██╗██╔══██║██║╚██╗██║██╔═██╗ ██║██║╚██╗██║██║   ██║
    ██║ ╚═╝ ██║╚██████╔╝██║███████╗███████╗   ██║   ██║  ██║██║  ██║██║ ╚████║██║  ██╗██║██║ ╚████║╚██████╔╝
    ╚═╝     ╚═╝ ╚═════╝ ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝
]]

M.logo.three = [[
⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣴⣶⣶⣶⣶⣶⠶⣶⣤⣤⣀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⣤⣾⣿⣿⣿⠁⠀⢀⠈⢿⢀⣀⠀⠹⣿⣿⣿⣦⣄⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⠿⠀⠀⣟⡇⢘⣾⣽⠀⠀⡏⠉⠙⢛⣿⣷⡖⠀
⠀⠀⠀⠀⠀⣾⣿⣿⡿⠿⠷⠶⠤⠙⠒⠀⠒⢻⣿⣿⡷⠋⠀⠴⠞⠋⠁⢙⣿⣄
⠀⠀⠀⠀⢸⣿⣿⣯⣤⣤⣤⣤⣤⡄⠀⠀⠀⠀⠉⢹⡄⠀⠀⠀⠛⠛⠋⠉⠹⡇
⠀⠀⠀⠀⢸⣿⣿⠀⠀⠀⣀⣠⣤⣤⣤⣤⣤⣤⣤⣼⣇⣀⣀⣀⣛⣛⣒⣲⢾⡷
⢀⠤⠒⠒⢼⣿⣿⠶⠞⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⣼⠃
⢮⠀⠀⠀⠀⣿⣿⣆⠀⠀⠻⣿⡿⠛⠉⠉⠁⠀⠉⠉⠛⠿⣿⣿⠟⠁⠀⣼⠃⠀
⠈⠓⠶⣶⣾⣿⣿⣿⣧⡀⠀⠈⠒⢤⣀⣀⡀⠀⠀⣀⣀⡠⠚⠁⠀⢀⡼⠃⠀⠀
⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣷⣤⣤⣤⣤⣭⣭⣭⣭⣭⣥⣤⣤⣤⣴⣟⠁
====MUIZZYRANKING====
--             ]]

return M
