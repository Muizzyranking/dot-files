---@class utils.ui
local M = {}
M.colorscheme = "habamax"

------------------------------------------------------------
-- sets the colorscheme
---@param colorscheme? string
------------------------------------------------------------
function M.set_colorscheme(colorscheme)
  if vim.g.vscode then
    return
  end
  M.colorscheme = colorscheme or M.colorscheme

  -- Create an autocmd that will apply the colorscheme when LazyVim is loaded
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    callback = function()
      local ok = pcall(function()
        vim.cmd.colorscheme(M.colorscheme)
      end)
      if not ok then
        Utils.notify.error("Failed to load colorscheme: " .. M.colorscheme)
        M.colorscheme = "habamax"
        pcall(function()
          vim.cmd.colorscheme(M.colorscheme)
        end)
      end
    end,
  })
end

function M.foldexpr()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].ts_folds == nil then
    -- as long as we don't have a filetype, don't bother
    -- checking if treesitter is available (it won't)
    if vim.bo[buf].filetype == "" then
      return "0"
    end
    if vim.bo[buf].filetype:find("dashboard") then
      vim.b[buf].ts_folds = false
    else
      vim.b[buf].ts_folds = pcall(vim.treesitter.get_parser, buf)
    end
  end
  return vim.b[buf].ts_folds and vim.treesitter.foldexpr() or "0"
end

function M.foldtext_add(foldtext, highlight_add, highlight_sep)
  local foldtext_as_string = ""
  for _, foldtext_part in ipairs(foldtext) do
    foldtext_as_string = foldtext_as_string .. foldtext_part[1]
  end

  local folded_line_count = vim.v.foldend - vim.v.foldstart + 1
  local sep = " "
  local text = "  (length " .. folded_line_count .. ")"
  local ret = {
    { "  ", highlight_sep or "Folded" },
    { sep, highlight_sep or "FoldedSep" },
    { text, highlight_add },
  }

  return ret
end

function M.foldtext()
  -- Line number of first line of fold when fold is created,
  -- i.e. when `opt.foldtext` is evaluated.
  local pos = vim.v.foldstart

  -- String of first line of fold.
  local line = vim.api.nvim_buf_get_lines(0, pos - 1, pos, false)[1]

  -- Get language of current buffer.
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)

  -- Create `LanguageTree`, i.e. parser object, for current buffer filetype.
  local parser = vim.treesitter.get_parser(0, lang)

  if parser == nil then
    return vim.fn.foldtext()
  end

  -- Get `highlights` query for current buffer parser, as table from file,
  -- which gives information on highlights of tree nodes produced by parser.
  local query = vim.treesitter.query.get(parser:lang(), "highlights")

  if query == nil then
    return vim.fn.foldtext()
  end

  -- Partial TSTree for buffer, including root TSNode, and TSNodes of folded line.
  -- PERF: Only parsing needed range, as parsing whole file would be slower.
  local tree = parser:parse({ pos - 1, pos })[1]

  local result = {}
  local line_pos = 0
  local prev_range = { 0, 0 }

  -- Loop through matched "captures", i.e. node-to-capture-group pairs,
  -- for each TSNode in given range.
  -- Each TSNode could occur several times in list, i.e. map to several capture groups,
  -- and each capture group could be used by several TSNodes.
  for id, node, _ in query:iter_captures(tree:root(), 0, pos - 1, pos) do
    -- Name of capture group from query, for current capture.
    local name = query.captures[id]

    -- Text of captured node.
    local text = vim.treesitter.get_node_text(node, 0)

    -- Range, i.e. lines in source file, captured TSNode spans, where row is first line of fold.
    local start_row, start_col, end_row, end_col = node:range()

    -- Include part of folded line between captured TSNodes, i.e. whitespace,
    -- with arbitrary highlight group, e.g. "Folded", in final `foldtext`.
    if start_col > line_pos then
      table.insert(result, { line:sub(line_pos + 1, start_col), "Folded" })
    end

    -- For control flow analysis, break if TSNode does not have proper range.
    if end_col == nil or start_col == nil then
      break
    end

    -- Move `line_pos` to end column of current node,
    -- thus ensuring next loop iteration includes whitespace between TSNodes.
    line_pos = end_col

    -- Save source code range current TSNode spans, so current TSNode can be ignored if
    -- next capture is for TSNode covering same section of source code.
    local range = { start_col, end_col }

    -- Use language specific highlight, if it exists.
    local highlight = "@" .. name
    local highlight_lang = highlight .. "." .. lang
    if vim.fn.hlexists(highlight_lang) then
      highlight = highlight_lang
    end

    -- Insert TSNode text itself, with highlight group from treesitter.
    if range[1] == prev_range[1] and range[2] == prev_range[2] then
      -- Overwrite previous capture, as it was for same range from source code.
      result[#result] = { text, highlight }
    else
      -- Insert capture for TSNode covering new range of source code.
      table.insert(result, { text, highlight })
      prev_range = range
    end
  end

  local add = M.foldtext_add(result, "@keyword", "@comment")
  for _, v in ipairs(add) do
    table.insert(result, v)
  end

  return result
end

-- close floating windows
function M.close_floats()
  vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win)
      return vim.api.nvim_win_get_config(win).relative ~= ""
    end)
    :each(function(win)
      vim.api.nvim_win_close(win, true)
    end)
end

function M.refresh(close_floats)
  if close_floats then
    M.close_floats()
  end
  pcall(vim.cmd, "nohlsearch")
  pcall(vim.cmd, "diffupdate")
  pcall(vim.cmd, "normal! \\<C-L>")
  vim.schedule(function()
    pcall(vim.cmd, "e!")
  end)
  vim.cmd("redraw!")
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
