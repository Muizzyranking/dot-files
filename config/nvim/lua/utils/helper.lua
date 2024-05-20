local notify = require("utils.notify")
local M = {}

-----------------------------------------------------------
-- Create a new file
-----------------------------------------------------------
M.new_file = function()
  -- Ask for the file path and name
  local path_and_filename = vim.fn.input("Enter file name: ")
  -- Check if the prompt was canceled
  if path_and_filename == "" then
    return
  end
  -- Split the input into path and filename
  local path, filename = vim.fn.fnamemodify(path_and_filename, ":p:h"), vim.fn.fnamemodify(path_and_filename, ":t")
  -- Create the necessary directories if they don't exist
  vim.fn.mkdir(path, "p")
  -- Combine the path and filename
  local full_path = path .. "/" .. filename
  -- Create the file
  local success, error_msg = pcall(vim.fn.writefile, { "" }, full_path)
  if not success then
    notify.warn("Error creating file: " .. error_msg, { title = "File" })
    return
  end

  -- Open the new file in a new buffer
  vim.cmd("e " .. full_path)
  notify.info(path_and_filename .. " created", { title = "File" })
end

-----------------------------------------------------------
-- Toggle diagnostics
-----------------------------------------------------------
local enabled = true
function M.toggle_diagnostics()
  -- if this Neovim version supports checking if diagnostics are enabled
  -- then use that for the current state
  ---@diagnostic disable-next-line: deprecated
  if vim.diagnostic.is_disabled then
    ---@diagnostic disable-next-line: deprecated
    enabled = not vim.diagnostic.is_disabled()
  end
  enabled = not enabled

  if enabled then
    vim.diagnostic.enable()
    notify.info("Enabled diagnostics", { title = "Diagnostics" })
  else
    ---@diagnostic disable-next-line: deprecated
    vim.diagnostic.disable()
    notify.warn("Disabled diagnostics", { title = "Diagnostics" })
  end
end

-----------------------------------------------------------
-- Toggle line wrap
-----------------------------------------------------------
function M.toggle_line_wrap()
  local wrapped = vim.opt.wrap:get()
  vim.opt.wrap = not wrapped -- Toggle wrap based on current state
  if wrapped then
    notify.warn("Line wrap disabled.", { title = "Option" })
  else
    vim.opt.wrap = true -- Toggle wrap based on current state
    notify.info("Line wrap enabled.", { title = "Option" })
  end
end

-----------------------------------------------------------
-- Toggle spell checking
-----------------------------------------------------------
function M.toggle_spell()
  local spell = vim.opt.spell:get()
  vim.opt.spell = not spell -- Toggle wrap based on current state
  if spell then
    notify.warn("Spell disabled.", { title = "Option" })
  else
    vim.opt.spell = true -- Toggle wrap based on current state
    notify.info("Spell enabled.", { title = "Option" })
  end
end

-----------------------------------------------------------
-- Toggle autoformat
-----------------------------------------------------------
-- function M.toggle_autoformat()
--   if vim.g.autoformat == nil or not vim.g.autoformat then
--     vim.g.autoformat = true
--     notify.info("Auto Format enabled.", { title = "Option" })
--   else
--     vim.g.autoformat = false
--     notify.warn("Auto Format disabled.", { title = "Option" })
--   end
-- end

function M.toggle_autoformat(buffer)
  local disable_autoformat_global = vim.g.disable_autoformat
  local disable_autoformat_buffer = vim.b.disable_autoformat or false

  if buffer then
    -- Toggle autoformat for the current buffer only
    vim.b.disable_autoformat = not disable_autoformat_buffer
    if vim.b.disable_autoformat then
      notify.warn("Buffer autoformatting disabled", { title = "Auto Format" })
    else
      if disable_autoformat_global then
        notify.warn("Buffer autoformatting enabled (Global autoformatting is disabled)", { title = "Auto Format" })
      else
        notify.info("Buffer autoformatting enabled", { title = "Auto Format" })
      end
    end
  else
    -- Toggle autoformat globally
    vim.g.disable_autoformat = not disable_autoformat_global
    vim.b.disable_autoformat = vim.g.disable_autoformat
    if vim.g.disable_autoformat then
      notify.warn("Global autoformatting disabled", { title = "Auto Format" })
    else
      notify.info("Global autoformatting enabled", { title = "Auto Format" })
    end
  end
end

function M.make_file_executable()
  local cmd = "chmod +x " .. vim.fn.expand("%")
  local output = vim.fn.system(cmd)

  if vim.v.shell_error == 0 then
    notify.info("File made executable", { title = "Option" })
  else
    notify.warn("Error making file executable: " .. output, { title = "Options" })
  end
end

return M
