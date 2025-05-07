---@class utils.actions
local M = {}
local api = vim.api

-----------------------------------------------------------
-- Make the current file executable
-----------------------------------------------------------
function M.toggle_file_executable(state, filename)
  filename = filename or Utils.get_filename()
  local cmd = ("chmod %s %s"):format(state and "-x" or "+x", filename)
  local success_message = ("File made %s"):format(state and "unexecutable" or "executable")
  local error_message = ("Error making file %s"):format(state and "unexecutable" or "executable")

  local output = vim.fn.system(cmd)
  local err = vim.v.shell_error == 0
  Utils.notify[err and "info" or "warn"](
    err and success_message or error_message .. ": " .. output,
    { title = "Options" }
  )
end

-------------------------------------
-- Duplicate the current line.
-------------------------------------
function M.duplicate_line()
  local current_line = api.nvim_get_current_line() -- Get the current line
  local cursor = api.nvim_win_get_cursor(0) -- Get current cursor position
  api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, { current_line })
  api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] }) -- Move cursor to the duplicated line
end

-------------------------------------
-- Duplicate the currently selected lines in visual mode.
-------------------------------------
function M.duplicate_selection()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local selected_lines = api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  api.nvim_buf_set_lines(0, end_line, end_line, false, selected_lines)
  local new_cursor_line = math.min(end_line + #selected_lines, api.nvim_buf_line_count(0))
  api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  api.nvim_win_set_cursor(0, { new_cursor_line, 0 })
end
