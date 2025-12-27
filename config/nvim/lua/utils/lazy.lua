---@class utils.lazy
local M = {}

---------------------------------------------------------------
-- Check if a plugin is installed
---@param plugin string
---@return boolean
---------------------------------------------------------------
function M.has(plugin)
  return require("lazy.core.config").spec.plugins[plugin] ~= nil
end

---------------------------------------------------------------
-- Get the options for a plugin
---@param name string
---@return table
---------------------------------------------------------------
function M.opts(name)
  local plugin = require("lazy.core.config").plugins[name]
  if not plugin then
    return {}
  end
  local Plugin = require("lazy.core.plugin")
  return Plugin.values(plugin, "opts", false)
end

---------------------------------------------------------------
-- checks if a plugin is loaded
---@param name string name of the plugin
---------------------------------------------------------------
function M.is_loaded(name)
  local Config = require("lazy.core.config")
  return Config.plugins[name] and Config.plugins[name]._.loaded
end

--------------------------------------------------------------------------
-- Execute a function when a plugin is loaded or schedule it for later if the plugin is not yet loaded.
---@param name string
---@param fn function
--------------------------------------------------------------------------
function M.on_load(name, fn)
  if M.is_loaded(name) then
    fn(name)
  else
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyLoad",
      callback = function(event)
        if event.data == name then
          fn(name)
          return true
        end
      end,
    })
  end
end

function M.on_very_lazy(fn, opts)
  opts = opts or {}
  opts.pattern = "VeryLazy"
  opts.callback = function(e)
    if type(fn) == "function" then
      fn(e)
    end
  end
  vim.api.nvim_create_autocmd("User", opts)
end

return M
