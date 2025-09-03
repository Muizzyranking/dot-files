local M = {}

--[[
This module changes a python string to an f-string when {{ is typed.
If it is already an f-string, it insert { normally.

example:
var = "value { |" adding { -> var = f"value { | }"
--]]

function M.handle_brace()
  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)
  local row = pos[1] - 1 -- 0-based
  local col = pos[2] -- 0-based

  if col == 0 then
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  local prev_char_range = { row, col - 1, row, col }
  local prev_char =
    vim.api.nvim_buf_get_text(0, prev_char_range[1], prev_char_range[2], prev_char_range[3], prev_char_range[4], {})[1]

  if prev_char ~= "{" then
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  -- Check if inside a string using treesitter
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  local string_node = node
  while string_node and string_node:type() ~= "string" do
    string_node = string_node:parent()
  end

  if not string_node then
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  -- Find string_start child
  local start_node = nil
  for child in string_node:iter_children() do
    if child:type() == "string_start" then
      start_node = child
      break
    end
  end

  if not start_node then
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  local start_text = vim.treesitter.get_node_text(start_node, 0)

  -- Determine if triple quoted and extract components
  local quote_len = 1
  local quote = nil
  local prefixes = nil

  if start_text:match('"""$') then
    quote_len = 3
    quote = '"""'
    prefixes = start_text:sub(1, -4) -- Everything except the last 3 characters
  elseif start_text:match("'''$") then
    quote_len = 3
    quote = "'''"
    prefixes = start_text:sub(1, -4) -- Everything except the last 3 characters
  elseif start_text:match('"$') then
    quote = '"'
    prefixes = start_text:sub(1, -2) -- Everything except the last character
  elseif start_text:match("'$") then
    quote = "'"
    prefixes = start_text:sub(1, -2) -- Everything except the last character
  else
    -- Fallback - shouldn't happen with valid Python strings
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  -- Check if already an f-string (case insensitive)
  local has_f = prefixes:lower():find("f") ~= nil

  if has_f then
    -- Already f-string, insert the second '{'
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  local new_prefixes = "f" .. prefixes
  local new_start_text = new_prefixes .. quote

  local srow, scol, _, ecol = start_node:range() -- 0-based
  local old_len = ecol - scol
  local new_len = #new_start_text
  local delta = 0
  if srow == row then delta = new_len - old_len end

  vim.api.nvim_buf_set_text(0, srow, scol, srow, ecol, { new_start_text })

  local insert_col = col + delta

  vim.api.nvim_buf_set_text(0, row, insert_col, row, insert_col, { "}" })

  vim.api.nvim_win_set_cursor(win, { pos[1], insert_col })
end

function M.setup(opts)
  opts = opts or {}
  opts.buffer = opts.buffer or true
  vim.keymap.set("i", "{", function()
    M.handle_brace()
  end, { buffer = opts.buffer, noremap = true, silent = true, desc = "Insert f-string brace" })
end

return M
