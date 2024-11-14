---@class utils.keys
local M = {}

-----------------------------------------------------------
-- Create a new file
-----------------------------------------------------------
M.new_file = function()
  local path_and_filename = vim.fn.input("Enter file name: ")
  if path_and_filename == "" then
    return
  end
  local path, filename = vim.fn.fnamemodify(path_and_filename, ":p:h"), vim.fn.fnamemodify(path_and_filename, ":t")
  vim.fn.mkdir(path, "p")
  local full_path = path .. "/" .. filename
  local success, error_msg = pcall(vim.fn.writefile, { "" }, full_path)
  if not success then
    Utils.notify.warn("Error creating file: " .. error_msg, { title = "File" })
    return
  end
  vim.cmd("e " .. full_path)
  Utils.notify.info(path_and_filename .. " created", { title = "File" })
end

-----------------------------------------------------------
-- Toggle diagnostics
-----------------------------------------------------------
local spell_enabled = true
function M.toggle_diagnostics()
  if vim.diagnostic.is_disabled then
    spell_enabled = not vim.diagnostic.is_disabled()
  end
  spell_enabled = not spell_enabled

  if spell_enabled then
    vim.diagnostic.enable()
    Utils.notify.info("Enabled diagnostics", { title = "Diagnostics" })
  else
    vim.diagnostic.disable()
    Utils.Utils.notify.warn("Disabled diagnostics", { title = "Diagnostics" })
  end
end

-----------------------------------------------------------
-- Toggle line wrap
-----------------------------------------------------------
function M.toggle_line_wrap()
  local wrapped = vim.opt.wrap:get()
  vim.opt.wrap = not wrapped -- Toggle wrap based on current state
  if wrapped then
    Utils.notify.warn("Line wrap disabled.", { title = "Option" })
  else
    vim.opt.wrap = true -- Toggle wrap based on current state
    Utils.notify.info("Line wrap enabled.", { title = "Option" })
  end
end

-----------------------------------------------------------
-- Toggle spell checking
-----------------------------------------------------------
function M.toggle_spell()
  local spell = vim.opt.spell:get()
  vim.opt.spell = not spell -- Toggle wrap based on current state
  if spell then
    Utils.notify.warn("Spell disabled.", { title = "Option" })
  else
    vim.opt.spell = true -- Toggle wrap based on current state
    Utils.notify.info("Spell enabled.", { title = "Option" })
  end
end

-----------------------------------------------------------
-- Make the current file executable
-----------------------------------------------------------
function M.toggle_file_executable()
  local filename = vim.fn.expand("%")
  local cmd, success_message, error_message
  if Utils.is_executable(filename) then
    cmd = "chmod -x " .. filename
    success_message = "File made unexecutable"
    error_message = "Error making file unexecutable"
  else
    cmd = "chmod +x " .. filename
    success_message = "File made executable"
    error_message = "Error making file executable"
  end
  local output = vim.fn.system(cmd)

  if vim.v.shell_error == 0 then
    Utils.notify.info(success_message, { title = "Option" })
  else
    Utils.notify.warn(error_message .. ": " .. output, { title = "Option" })
  end
end

-------------------------------------
-- Duplicate the current line.
-------------------------------------
M.duplicate_line = function()
  local current_line = vim.api.nvim_get_current_line() -- Get the current line
  local cursor = vim.api.nvim_win_get_cursor(0) -- Get current cursor position
  vim.api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, { current_line })
  vim.api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] }) -- Move cursor to the duplicated line
end

-------------------------------------
-- Duplicate the currently selected lines in visual mode.
-------------------------------------
M.duplicate_selection = function()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local selected_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, selected_lines)
  local new_cursor_line = math.min(end_line + #selected_lines, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  vim.api.nvim_win_set_cursor(0, { new_cursor_line, 0 })
end

-------------------------------------
-- Remove a buffer, prompting to save changes if the buffer is modified.
---@param buf number|nil
-------------------------------------
M.bufremove = function(buf)
  buf = buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf

  if vim.bo.modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
    if choice == 0 then -- Cancel
      return
    end
    if choice == 1 then -- Yes
      vim.cmd.write()
    end
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
        return
      end
      -- Try using alternate buffer
      local alt = vim.fn.bufnr("#")
      if alt ~= buf and vim.fn.buflisted(alt) == 1 then
        vim.api.nvim_win_set_buf(win, alt)
        return
      end

      -- Try using previous buffer
      ---@diagnostic disable-next-line: param-type-mismatch
      local has_previous = pcall(vim.cmd, "bprevious")
      if has_previous and buf ~= vim.api.nvim_win_get_buf(win) then
        return
      end

      -- Create new listed buffer
      local new_buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_win_set_buf(win, new_buf)
    end)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    ---@diagnostic disable-next-line: param-type-mismatch
    pcall(vim.cmd, "bdelete! " .. buf)
  end
end

return M
