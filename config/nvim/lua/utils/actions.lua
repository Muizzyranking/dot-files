---@class utils.actions
local M = {}
local api = vim.api

-----------------------------------------------------------
-- Make the current file executable
---@param state boolean true to make unexecutable, false to make executable
---@param filepath? string The file to change permissions for (defaults to current file)
---@param notify? boolean Whether to show a notification (default: true)
-----------------------------------------------------------
function M.toggle_file_executable(state, filepath, notify)
  filepath = filepath or Utils.get_filepath()
  local flag = state and "-x" or "+x"
  local success, output = Utils.run_command({ "chmod", flag, filepath }, { trim = true })
  local success_message = ("File made %s"):format(state and "unexecutable" or "executable")
  local error_message = ("Error making file %s"):format(state and "unexecutable" or "executable")

  local level = "info"
  if success then
    level = state and "warn" or "info"
  else
    level = "warn"
  end
  if notify ~= false then
    Utils.notify[level](success and success_message or error_message .. ": " .. output, { title = "Options" })
  end
end

-------------------------------------
-- Duplicate the current line.
-------------------------------------
function M.duplicate_line()
  if Utils.ignore_buftype() then return end
  local current_line = api.nvim_get_current_line()
  local cursor = api.nvim_win_get_cursor(0)
  api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, { current_line })
  api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] })
end

-------------------------------------
-- Duplicate the currently selected lines in visual mode.
-------------------------------------
function M.duplicate_selection()
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

local function is_in_indent()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col(".")
  return line:sub(1, col - 1):find("^%s*$") ~= nil
end

local function can_jump_after_close()
  return vim.fn.search([=[[)\]}"'`]]=], "cnW") ~= 0
end

local function can_jump_before_open()
  return vim.fn.search([=[[(\[{"'`]]=], "cnbW") ~= 0
end

local function do_jump_after_close()
  local pos = vim.fn.search([=[[)\]}"'`]]=], "cW")
  if pos ~= 0 then
    -- Move cursor one position right
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] + 1 })
    return true
  end
  return false
end

local function do_jump_before_open()
  return vim.fn.search([=[[(\[{"'`]]=], "bW") ~= 0
end

---------------------------------------
-- jump after closing pair or insert tab
---------------------------------------
function M.smart_tab()
  if vim.fn.mode() ~= "i" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
    return
  end

  if is_in_indent() then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-t>", true, false, true), "n", false)
  elseif can_jump_after_close() then
    do_jump_after_close()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
  end
end

---------------------------------------
-- jump before closing pair or insert s-tab
---------------------------------------
function M.smart_shift_tab()
  if vim.fn.mode() ~= "i" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
    return
  end

  -- Check conditions in order and execute first matching action
  if is_in_indent() then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-d>", true, false, true), "n", false)
  elseif can_jump_before_open() then
    do_jump_before_open()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
  end
end

return M
