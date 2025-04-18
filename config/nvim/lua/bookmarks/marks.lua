local M = {}
local cache = {}
local mark_cache = {}
local refresh_timer = nil
local refresh_rate = 50 -- ms

function M.setup()
  if not refresh_timer then
    refresh_timer = (vim.uv or vim.loop).new_timer()
    refresh_timer:start(refresh_rate, refresh_rate, function()
      cache = {}
      mark_cache = {}
    end)
  end
  -- vim.o.statuscolumn = [[%!v:lua.combined_statuscolumn()]]
  vim.o.statuscolumn = [[%!v:lua.require'bookmarks.marks'.combined_statuscolumn()]]
end

function M.get_buffer_marks(buf)
  if mark_cache[buf] then
    return mark_cache[buf]
  end

  local result = {}
  local marks = vim.fn.getmarklist(buf)
  vim.list_extend(marks, vim.fn.getmarklist())

  for _, mark in ipairs(marks) do
    if mark.pos[1] == buf and mark.mark:match("[a-z]") then
      local lnum = mark.pos[2]
      result[lnum] = result[lnum] or {}
      table.insert(result[lnum], {
        text = " ",
        texthl = "DiagnosticError",
        type = "mark",
        is_global = false,
        mark_char = mark.mark:sub(2),
      })
    end
    if mark.pos[1] == buf and mark.mark:match("[A-Z]") then
      local lnum = mark.pos[2]
      result[lnum] = result[lnum] or {}
      table.insert(result[lnum], {
        text = " ",
        texthl = "DiagnosticInfo",
        type = "mark",
        is_global = true,
        mark_char = mark.mark:sub(2),
      })
    end
  end

  mark_cache[buf] = result
  return result
end

function M.format_mark_icon(mark)
  if not mark then
    return ""
  end

  local text = mark.text or ""

  if mark.texthl then
    return "%#" .. mark.texthl .. "#" .. text .. "%*"
  else
    return mark.text
  end
end

function M.combined_statuscolumn()
  -- Initialize if not already done
  if not refresh_timer then
    M.setup()
  end

  -- Get current context
  local win = vim.g.statusline_winid
  local buf = vim.api.nvim_win_get_buf(win)
  local lnum = vim.v.lnum

  -- Create cache key
  local key = ("%d:%d:%d:%d:%d"):format(win, buf, lnum, vim.v.virtnum ~= 0 and 1 or 0, vim.v.relnum)
  if cache[key] then
    return cache[key]
  end

  -- Get original statuscolumn
  local original_status = require("snacks.statuscolumn").get()

  -- Get marks for this line
  local buf_marks = M.get_buffer_marks(buf)
  local line_marks = buf_marks[lnum] or {}

  -- Create mark icon with highlighting
  local mark_icon = ""
  if #line_marks > 0 then
    mark_icon = M.format_mark_icon(line_marks[1])
  end

  -- Create result and cache it
  local result
  if mark_icon ~= "" then
    original_status = original_status:gsub("  ", "", 1)
    result = mark_icon .. original_status
  else
    result = original_status
  end

  cache[key] = result
  return result
end

function M.jump_mark(buffer, opts)
  buffer = buffer or vim.api.nvim_get_current_buf()
  opts = opts or {}

  local direction = opts.direction or 1 -- Default to forward
  local global_only = opts.global or false

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local marks = {}

  -- Get all marks in the buffer
  local buf_marks = vim.fn.getmarklist(buffer)
  local global_marks = vim.fn.getmarklist()

  -- Filter marks based on global_only parameter
  if global_only then
    -- Only include global marks (uppercase)
    for _, mark in ipairs(global_marks) do
      if mark.pos[1] == buffer and mark.mark:match("[A-Z]") then
        table.insert(marks, { line = mark.pos[2], col = mark.pos[3], char = mark.mark:sub(2) })
      end
    end
  else
    -- Include local marks (lowercase)
    for _, mark in ipairs(buf_marks) do
      if mark.pos[1] == buffer and mark.mark:match("[a-z]") then
        table.insert(marks, { line = mark.pos[2], col = mark.pos[3], char = mark.mark:sub(2) })
      end
    end
  end

  -- Sort marks by line number
  table.sort(marks, function(a, b)
    return a.line < b.line
  end)

  if #marks == 0 then
    local mark_type = global_only and "global" or "local"
    vim.api.nvim_echo({ { ("No " .. mark_type .. " marks found in buffer"), "WarningMsg" } }, false, {})
    return false
  end

  -- Find the next/previous mark based on direction
  local target_mark = nil

  if direction > 0 then
    -- Forward direction
    for _, mark in ipairs(marks) do
      if mark.line > current_line then
        target_mark = mark
        break
      end
    end

    -- Wrap around to first mark if needed
    if not target_mark then
      target_mark = marks[1]
    end
  else
    -- Backward direction
    for i = #marks, 1, -1 do
      if marks[i].line < current_line then
        target_mark = marks[i]
        break
      end
    end

    -- Wrap around to last mark if needed
    if not target_mark then
      target_mark = marks[#marks]
    end
  end

  -- Jump to the mark if found
  if target_mark then
    vim.api.nvim_win_set_cursor(0, { target_mark.line, target_mark.col - 1 })
    return true
  end

  return false
end

function M.delete_mark_current_line()
  local line_num = vim.fn.line(".")

  local marks = vim.fn.getmarklist(vim.fn.bufnr())
  local global_marks = vim.fn.getmarklist()

  for _, mark_list in ipairs({ marks, global_marks }) do
    for _, mark in ipairs(mark_list) do
      local mark_name = string.sub(mark.mark, 2)
      local mark_line = mark.pos[2]
      if mark_line == line_num then
        vim.cmd("delmarks " .. mark_name)
      end
    end
  end
end

return M
