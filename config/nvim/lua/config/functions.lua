local M = {}
local util = require("config.util")

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
    vim.api.nvim_err_writeln("Error creating file: " .. error_msg)
    return
  end

  -- Open the new file in a new buffer
  vim.cmd("e " .. full_path)
end

-----------------------------------------------------------
-- Toggle diagnostics
-----------------------------------------------------------
local enabled = true
function M.toggle_diagnostics()
  -- if this Neovim version supports checking if diagnostics are enabled
  -- then use that for the current state
  if vim.diagnostic.is_disabled then
    enabled = not vim.diagnostic.is_disabled()
  end
  enabled = not enabled

  if enabled then
    vim.diagnostic.enable()
    util.info("Enabled diagnostics", { title = "Diagnostics" })
  else
    vim.diagnostic.disable()
    util.warn("Disabled diagnostics", { title = "Diagnostics" })
  end
end

-----------------------------------------------------------
-- Toggle line wrap
-----------------------------------------------------------
function M.toggle_line_wrap()
  local wrapped = vim.opt.wrap:get()
  vim.opt.wrap = not wrapped -- Toggle wrap based on current state
  if wrapped then
    util.warn("Line wrap disabled.", { title = "Option" })
  else
    vim.opt.wrap = true -- Toggle wrap based on current state
    util.info("Line wrap enabled.", { title = "Option" })
  end
end

-----------------------------------------------------------
-- Toggle spell checking
-----------------------------------------------------------
function M.toggle_spell()
  local spell = vim.opt.spell:get()
  vim.opt.spell = not spell -- Toggle wrap based on current state
  if spell then
    util.warn("Spell disabled.", { title = "Option" })
  else
    vim.opt.spell = true -- Toggle wrap based on current state
    util.info("Spell enabled.", { title = "Option" })
  end
end

-----------------------------------------------------------
-- Toggle autoformat
-----------------------------------------------------------
function M.toggle_autoformat()
  if vim.g.autoformat == nil or not vim.g.autoformat then
    vim.g.autoformat = true
    util.info("Auto Format enabled.", { title = "Option" })
  else
    vim.g.autoformat = false
    util.warn("Auto Format disabled.", { title = "Option" })
  end
end

return M
