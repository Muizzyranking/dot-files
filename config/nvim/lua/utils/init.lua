---@class utils
---@field actions utils.actions
---@field bigfile utils.bigfile
---@field cmp utils.cmp
---@field discipline utils.discipline
---@field format utils.format
---@field hl utils.hl
---@field icons utils.icons
---@field lsp utils.lsp
---@field lualine utils.lualine
---@field map utils.map
---@field notify utils.notify
---@field root utils.root
---@field setup_lang utils.setup_lang
---@field ts utils.ts
---@field ui utils.ui
local M = {}

setmetatable(M, {
  __index = function(t, k)
    t[k] = require("utils." .. k)
    return t[k]
  end,
})

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
function M.get_opts(name)
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

--------------------------------------------------------------------------
-- lazily execute a function
---@param fn function
--------------------------------------------------------------------------
function M.on_very_lazy(fn)
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      fn()
    end,
  })
end

---------------------------------------------------------------
-- Check if the Neovim is running inside a TMUX session.
---@return boolean
---------------------------------------------------------------
M.is_in_tmux = function()
  return os.getenv("TMUX") ~= nil
end

---------------------------------------------------------------
-- Check if is a git repo.
---@return boolean
---------------------------------------------------------------
function M.is_in_git_repo()
  local handle, err = io.popen("git rev-parse --is-inside-work-tree 2>/dev/null")
  if not handle then
    M.notify.error("Failed to check git repository: " .. (err or "unknown error"))
    return false
  end

  local result = handle:read("*a")
  handle:close()

  if not result then
    M.notify.error("Failed to read git command output.")
    return false
  end

  return result:match("true") ~= nil
end

-------------------------------------
-- Checks if the path is executable
---@param path any
---@return boolean
-------------------------------------
M.is_executable = function(path)
  if path == "" then
    return false
  end
  local ok, result = pcall(vim.fn.executable, path)
  return ok and result == 1
end

---------------------------------------------------------------
-- Normalize path (handles ~, slashes, and trailing slashes)
---@param path string path to normalize
---------------------------------------------------------------
function M.norm(path)
  if path:sub(1, 1) == "~" then
    local home = vim.uv.os_homedir()
    if home:sub(-1) == "\\" or home:sub(-1) == "/" then
      home = home:sub(1, -2)
    end
    path = home .. path:sub(2)
  end
  path = path:gsub("\\", "/"):gsub("/+", "/")
  return path:sub(-1) == "/" and path:sub(1, -2) or path
end

local cache = {} ---@type table<(fun()), table<string, any>>
----------------------------------------
---@generic T: fun()
---@param fn T
---@return T
---------------------------------------
function M.memoize(fn)
  return function(...)
    local key = vim.inspect({ ... })
    cache[fn] = cache[fn] or {}
    if cache[fn][key] == nil then
      cache[fn][key] = fn(...)
    end
    return cache[fn][key]
  end
end

-----------------------------
-- shows nvim version
---@return string
-----------------------------
function M.nvim_version()
  local version = vim.version()
  local v = "v" .. version.major .. "." .. version.minor .. "." .. version.patch
  return v
end

--------------------------------
-- shows plugin status
---@return table
--------------------------------
function M.plugin_stats()
  local stats = require("lazy").stats()
  local updates = require("lazy.manage.checker").updated
  return {
    count = stats.count,
    loaded = stats.loaded,
    startuptime = (math.floor(stats.startuptime * 100 + 0.5) / 100),
    updates = #updates,
  }
end

-----------------------------------------------------------------
--- Normalize a value to ensure it’s always a list.
---@param value any # Input value
---@return string[]|table|nil # Listified value
-----------------------------------------------------------------
function M.ensure_list(value)
  if not value then
    return nil
  end
  if type(value) == "function" then
    value = value()
  end
  return type(value) == "string" and { value } or value
end

-----------------------------------------------------------------
--- Ensures a valid buffer number, defaulting to current buffer if none provided
---@param buf? number|nil # The buffer number to validate
---@return number # The validated buffer number
-----------------------------------------------------------------
function M.ensure_buf(buf)
  if not buf or buf == nil or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  return buf
end

-----------------------------------------------------------------
---@param buf? number # default: current buf
---@return string # filename
-----------------------------------------------------------------
function M.get_filename(buf)
  buf = M.ensure_buf(buf)
  return vim.api.nvim_buf_get_name(buf)
end

-----------------------------------------------------------------
-- checks if the system has internet access
-----------------------------------------------------------------
function M.has_internet_async()
  vim.fn.jobstart("ping -c 1 -W 1 github.com", {
    on_exit = function(job_id, exit_code, event)
      vim.g.has_internet = exit_code == 0
      if exit_code ~= 0 then
        vim.schedule(function()
          Utils.notify.warn("Internet connectivity check failed - some plugins may be disabled")
        end)
      end
    end,
  })
end

return M
