local M = {}

----------------------------------------------------------
--- Wrapper function for Neovim's notification system
---@param msg string The message to be displayed in the notification
---@param level? integer The log level of the notification
---@param opts? table Additional options for the notification
----------------------------------------------------------
function M.notify(msg, level, opts)
  opts = opts or {}
  opts.title = opts.title or "Neovim"
  level = level or vim.log.levels.INFO
  vim.notify(msg, level, opts)
end

-----------------------------
-- Display a warning message
---@param msg string
---@param opts? NotifyOpts
-----------------------------
function M.warn(msg, opts)
  opts = opts or {}
  local level = vim.log.levels.WARN
  M.notify(msg, level, opts)
end

-----------------------------
-- Display an informational message
---@param msg string
---@param opts? NotifyOpts
-----------------------------
function M.info(msg, opts)
  opts = opts or {}
  local level = vim.log.levels.INFO
  M.notify(msg, level, opts)
end

-----------------------------
-- Display an error message
---@param msg string
---@param opts? NotifyOpts
-----------------------------
function M.error(msg, opts)
  opts = opts or {}
  local level = vim.log.levels.ERROR
  M.notify(msg, level, opts)
end

return M
