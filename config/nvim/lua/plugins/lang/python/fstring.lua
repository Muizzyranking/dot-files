local M = {}

--[[
This module changes a python string to an f-string when {{ is typed.
If it is already an f-string, it insert { normally.
When not in a string, it auto-closes braces.

example:
var = "value { |" adding { -> var = f"value { | }"
--]]

-- Function to check if we're inside a string and get string info
local function get_string_info(line, col)
  local in_string = false
  local string_start = nil
  local string_quote = nil
  local is_fstring = false
  local i = 1

  while i <= col do
    local char = line:sub(i, i)

    if not in_string then
      -- Check for string start
      if char == '"' or char == "'" then
        -- Check for triple quotes
        local triple_quote = line:sub(i, i + 2)
        if triple_quote == '"""' or triple_quote == "'''" then
          string_quote = triple_quote
          i = i + 3
        else
          string_quote = char
          i = i + 1
        end

        -- Check for f-string prefix
        local prefix_start = i - #string_quote - 1
        while prefix_start > 0 do
          local prefix_char = line:sub(prefix_start, prefix_start)
          if prefix_char:match("%a") then
            if prefix_char:lower() == "f" then is_fstring = true end
            prefix_start = prefix_start - 1
          else
            break
          end
        end

        in_string = true
        string_start = i - #string_quote
      else
        i = i + 1
      end
    else
      -- Inside string, check for end
      if char == "\\" then
        -- Skip escaped character
        i = i + 2
      elseif line:sub(i, i + #string_quote - 1) == string_quote then
        in_string = false
        string_start = nil
        string_quote = nil
        is_fstring = false
        i = i + #string_quote
      else
        i = i + 1
      end
    end
  end

  return in_string, string_start, string_quote, is_fstring
end

function M.handle_brace()
  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)
  local row = pos[1] - 1 -- 0-based
  local col = pos[2] -- 0-based (cursor position)

  -- Get current line
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""

  -- Check if we're at the beginning of line
  if col == 0 then
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{}" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  local prev_char = line:sub(col, col) -- Character before cursor (1-based indexing)
  local in_string, string_start, string_quote, is_fstring = get_string_info(line, col)

  if not in_string then
    -- Not inside a string, auto-close
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{}" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  -- We are inside a string
  if is_fstring then
    -- Already an f-string, just insert single '{'
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  -- Regular string, not f-string yet
  if prev_char ~= "{" then
    -- First '{' in regular string, just insert it
    vim.api.nvim_buf_set_text(0, row, col, row, col, { "{" })
    vim.api.nvim_win_set_cursor(win, { pos[1], col + 1 })
    return
  end

  -- Second '{' - convert to f-string
  -- Find where to insert 'f' prefix
  local prefix_pos = string_start - 1
  while prefix_pos > 0 and line:sub(prefix_pos, prefix_pos):match("%a") do
    prefix_pos = prefix_pos - 1
  end
  prefix_pos = prefix_pos + 1

  -- Insert 'f' at the beginning of prefixes
  vim.api.nvim_buf_set_text(0, row, prefix_pos - 1, row, prefix_pos - 1, { "f" })

  -- Remove the previous '{' and insert '{}'
  local remove_start = col - 1 + 1 -- Adjust for the 'f' we just added
  vim.api.nvim_buf_set_text(0, row, remove_start, row, col + 1, { "{}" })

  -- Position cursor between the braces
  vim.api.nvim_win_set_cursor(win, { pos[1], remove_start + 1 })
end

function M.setup(opts)
  opts = opts or {}
  opts.buffer = opts.buffer or true
  vim.keymap.set("i", "{", function()
    M.handle_brace()
  end, { buffer = opts.buffer, noremap = true, silent = true, desc = "Insert f-string brace" })
end

return M
