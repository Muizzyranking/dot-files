---@class utils.actions
local M = {}
local api = vim.api

-----------------------------------------------------------
-- Make the current file executable
-----------------------------------------------------------
function M.toggle_file_executable(state, filename)
  filename = filename or Utils.get_filename()
  local flag = state and "-x" or "+x"
  local success, output = Utils.run_command({ "chmod", flag, filename }, { trim = true })
  local success_message = ("File made %s"):format(state and "unexecutable" or "executable")
  local error_message = ("Error making file %s"):format(state and "unexecutable" or "executable")

  local level = "info"
  if success then
    level = state and "warn" or "info"
  else
    level = "warn"
  end
  Utils.notify[level](success and success_message or error_message .. ": " .. output, { title = "Options" })
end

-------------------------------------
-- Duplicate the current line.
-------------------------------------
function M.duplicate_line()
  -- stylua: ignore
  if Utils.ignore_buftype() then return end
  local current_line = api.nvim_get_current_line() -- Get the current line
  local cursor = api.nvim_win_get_cursor(0) -- Get current cursor position
  api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, { current_line })
  api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] }) -- Move cursor to the duplicated line
end

-------------------------------------
-- Duplicate the currently selected lines in visual mode.
-------------------------------------
function M.duplicate_selection()
  -- stylua: ignore
  if Utils.ignore_buftype() then return end
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

M.__tmux_executed = false
function M.toggle_tmux(state)
  if not M.__tmux_executed then
    Utils.autocmd.exec_user_event("TmuxBarToggle")
    M.__tmux_executed = true
  end

  local status = state and "off" or "on"
  local success, output = Utils.run_command({ "tmux", "set-option", "-g", "status", status }, { trim = true })
  local notify_opts = { title = "Tmux" }
  if success then
    local bar_state = state and "Hide" or "Show"
    Utils.notify(("%s Tmux Bar"):format(bar_state), notify_opts)
  else
    Utils.notify.warn("Error toggling tmux: " .. output, notify_opts)
  end
end

return M
