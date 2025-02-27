---@class utils
---@field actions utils.actions
---@field cmp utils.cmp
---@field color_converter utils.color_converter
---@field format utils.format
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

-----------------------------------
-- reloads configs e.g kitty
---@param opts table
-----------------------------------
function M.reload_config(opts)
  if opts.cond ~= nil and not opts.cond then
    return
  end
  if not opts.cmd then
    M.notify.error("No command provided to reload config")
    return
  end
  local function reload_conf()
    local output = vim.fn.system(opts.cmd)
    local notify_opts = { title = opts.title or "Config" }
    local error = vim.v.shell_error ~= 0
    local mgs = ("%s %s %s"):format(
      error and "Error reloading" or "Reloaded",
      opts.title,
      error and ": " .. output or ""
    )
    M.notify[error and "error" or "info"](mgs, notify_opts)
  end
  M.map.set_keymap({
    "<leader>rr",
    reload_conf,
    desc = "Reload Config",
    silent = true,
    buffer = opts.buffer,
    icon = { icon = "󰑓 ", color = "orange" },
  })
end

-----------------------------------
-- create abbreviations
---@param word string
---@param new_word string
---@param opts table
-----------------------------------
function M.create_abbrev(word, new_word, opts)
  if not word or not new_word then
    return
  end
  opts = opts or {}
  local condition = opts.condition
  opts.condition = nil
  local mode = opts.mode or "ia"
  opts = vim.tbl_extend("force", opts or {}, {
    mode = nil,
    expr = true,
  })
  vim.keymap.set(mode, word, function()
    local cond = not condition or (type(condition) == "function" and condition())
    if cond then
      return new_word
    end
    return word
  end, opts)
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

return M
