---@class utils.folds
local M = {}
local query_cache = {}

--- Determines if the current buffer should have its view saved/loaded
--- Checks buffer type, file type, and file accessibility
---@return boolean # true if view should be saved, false otherwise
function M.should_save_view(buf)
  buf = Utils.ensure_buf(buf)
  -- stylua: ignore start
  if vim.b[buf].bigfile then return false end
  if Utils.ignore_buftype() then return false end
  if Utils.ignore_filetype() then return false end
  -- stylua: ignore end
  local full_path = vim.fn.expand("%:p")
  return full_path ~= "" and vim.fn.filereadable(full_path) == 1
end

-- Safely saves the current view
function M.safe_mkview()
  if M.should_save_view() then
    local ok, err = pcall(function()
      vim.cmd([[silent! mkview]])
    end)
    if not ok then
      Utils.notify.error({ "Error saving view:", err })
    end
  end
end

--- Safely loads view with treesitter awareness and timeout
--- Uses a one-shot approach instead of polling to avoid buggy behavior
function M.safe_loadview()
  if M.should_save_view() then
    local ok, err = pcall(function()
      vim.cmd([[silent! loadview]])
    end)
    if not ok then
      Utils.notify.error({ "Error loading view:", err })
    end
  end
end

----------------------------------------------------------
-- Custom fold expression using treesitter when available
-- Falls back to manual folding for unsupported file types
---@return string # fold level expression
----------------------------------------------------------
function M.foldexpr()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].ts_folds == nil then
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

----------------------------------------------------------
--- Adds fold information (line count) to fold text
---@param foldtext table[] # array of {text, highlight} pairs
---@param highlight_add? string # highlight group for added text
---@param highlight_sep? string # highlight group for separator
---@return table[] # modified foldtext with added information
----------------------------------------------------------
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

----------------------------------------------------------
-- Custom fold text with treesitter syntax highlighting
-- Falls back to default fold text if treesitter is unavailable
---@return string|table # fold text (string for fallback, table for highlighted)
----------------------------------------------------------
function M.foldtext()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local pos = vim.v.foldstart
  local line = vim.api.nvim_buf_get_lines(0, pos - 1, pos, false)[1]
  local parser = vim.treesitter.get_parser(0, lang)

  if parser == nil then
    return vim.fn.foldtext()
  end

  if not query_cache[lang] then
    query_cache[lang] = vim.treesitter.query.get(lang, "highlights")
  end
  local query = query_cache[lang]

  if query == nil then
    return vim.fn.foldtext()
  end

  -- PERF: Only parsing needed range, as parsing whole file would be slower.
  local tree = parser:parse({ pos - 1, pos })[1]

  local result = {}
  local line_pos = 0
  local prev_range = { 0, 0 }

  for id, node, _ in query:iter_captures(tree:root(), 0, pos - 1, pos) do
    local name = query.captures[id]
    local text = vim.treesitter.get_node_text(node, 0)
    local start_row, start_col, end_row, end_col = node:range()
    if start_col > line_pos then
      table.insert(result, { line:sub(line_pos + 1, start_col), "Folded" })
    end

    if end_col == nil or start_col == nil then
      break
    end

    line_pos = end_col

    local range = { start_col, end_col }

    -- Use language specific highlight, if it exists.
    local highlight = "@" .. name
    local highlight_lang = highlight .. "." .. lang
    if vim.fn.hlexists(highlight_lang) then
      highlight = highlight_lang
    end

    if range[1] == prev_range[1] and range[2] == prev_range[2] then
      result[#result] = { text, highlight }
    else
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

function M.setup()
  if vim.o.viewdir == "" then
    vim.o.viewdir = vim.fn.stdpath("state") .. "/view"
  end
  vim.fn.mkdir(vim.o.viewdir, "p")
  -- stylua: ignore start
  vim.opt.foldexpr       = "v:lua.require('utils.folds').foldexpr()"
  vim.opt.foldtext       = "v:lua.require('utils.folds').foldtext()"
  vim.opt.foldmethod     = "expr"
  vim.opt.foldenable     = true
  vim.opt.foldlevel      = 99
  vim.g.markdown_folding = 1
  -- stylua: ignore end
  Utils.autocmd.autocmd_augroup("remember_folds", {
    {
      events = { "BufWinLeave" },
      pattern = "*",
      desc = "save folds when leaving a buffer",
      callback = M.safe_mkview,
    },
    {
      events = { "BufWinEnter" },
      pattern = "*",
      desc = "load folds when entering a buffer",
      callback = M.safe_loadview,
    },
  })
end

return M
