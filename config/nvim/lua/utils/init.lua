---@class utils
---@field git utils.git
---@field icons utils.icons
---@field keys utils.keys
---@field lsp utils.lsp
---@field format utils.format
---@field notify utils.notify
---@field runner utils.runner
---@field terminal utils.terminal
---@field ui utils.ui
---@field lualine utils.lualine

--------------------------
-- Module definition
--------------------------
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
function M.opts(name)
  local plugin = require("lazy.core.config").plugins[name]
  if not plugin then
    return {}
  end
  local Plugin = require("lazy.core.plugin")
  return Plugin.values(plugin, "opts", false)
end

--------------------------------------------------------------------------
-- Execute a function when a plugin is loaded or schedule it for later if the plugin is not yet loaded.
---@param name string
---@param fn function
--------------------------------------------------------------------------
function M.on_load(name, fn)
  local Config = require("lazy.core.config")
  if Config.plugins[name] and Config.plugins[name]._.loaded then
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

function M.on_very_lazy(fn)
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      fn()
    end,
  })
end

---------------------------------------------------------------
-- Fast implementation to check if a table is a list
---@param t table
---------------------------------------------------------------
function M.is_list(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then
      return false
    end
  end
  return true
end

----------------------------------------------------
-- Check if a value can be merged
---@param v any The value to check
---@return boolean Whether the value can be merged
----------------------------------------------------
local function can_merge(v)
  return type(v) == "table" and (vim.tbl_isempty(v) or not M.is_list(v))
end

----------------------------------------------------
-- Merge multiple tables
---@param ... any Tables to merge
---@return table Merged table
----------------------------------------------------
function M.merge(...)
  local ret = select(1, ...)
  if ret == vim.NIL then
    ret = nil
  end
  for i = 2, select("#", ...) do
    local value = select(i, ...)
    if can_merge(ret) and can_merge(value) then
      for k, v in pairs(value) do
        ret[k] = M.merge(ret[k], v)
      end
    elseif value == vim.NIL then
      ret = nil
    elseif value ~= nil then
      ret = value
    end
  end
  return ret
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
  local handle = io.popen("git rev-parse --is-inside-work-tree 2>/dev/null")
  local result = handle:read("*a")
  handle:close()
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
--- Find the root directory of a project based on specified patterns
---@param buf number The buffer number
---@param patterns string|table The pattern(s) to search for
---@return string The root directory path or "." if not found
---------------------------------------------------------------
function M.find_root_directory(buf, patterns)
  -- Convert string patterns to a table if only one pattern is provided
  if type(patterns) == "string" then
    patterns = { patterns }
  end

  -- Retrieve the buffer path or current working directory if buffer path is unavailable
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    path = vim.uv.cwd()
  else
    -- Resolve the real path and normalize it
    path = vim.uv.fs_realpath(path) or path

    -- Normalize the path (expand ~, replace backslashes, and remove trailing slash)
    ---@diagnostic disable-next-line: param-type-mismatch
    if path:sub(1, 1) == "~" then
      local home = vim.uv.os_homedir()
      if home:sub(-1) == "\\" or home:sub(-1) == "/" then
        home = home:sub(1, -2)
      end
      ---@diagnostic disable-next-line: param-type-mismatch
      path = home .. path:sub(2)
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    path = path:gsub("\\", "/"):gsub("/+", "/")
    if path:sub(-1) == "/" then
      path = path:sub(1, -2)
    end
  end

  -- Search for a pattern match in the filesystem
  local pattern = vim.fs.find(function(name)
    for _, p in ipairs(patterns) do
      if name == p or (p:sub(1, 1) == "*" and name:find(vim.pesc(p:sub(2)) .. "$")) then
        return true
      end
    end
    return false
  end, { path = path, upward = true })[1]

  -- Return the directory containing the matched pattern, or "." if not found
  return pattern and vim.fs.dirname(pattern) or "."
end

---------------------------------------------------------------
--- Set keymap using which key
---@param mappings MapTable
---------------------------------------------------------------
function M.map(mappings)
  local keys = {}
  if type(mappings[1]) ~= "table" then
    mappings = { mappings }
  end
  for _, mapping in ipairs(mappings) do
    local lhs, rhs = mapping[1], mapping[2]
    local map = {
      lhs,
      rhs,
      desc = mapping.desc or "",
      mode = mapping.mode or "n",
    }
    if mapping.buffer then
      map.buffer = mapping.buffer
    end
    if mapping.icon then
      map.icon = mapping.icon
    end
    if mapping.silent ~= nil then
      map.silent = mapping.silent
    end
    if mapping.remap ~= nil then
      map.remap = mapping.remap
    end
    table.insert(keys, map)
    if not M.has("which-key.nvim") then
      local opts = {}
      opts.desc = map.desc
      vim.keymap.set(map.mode, lhs, rhs, opts)
    end
  end
  M.on_load("which-key.nvim", function()
    require("which-key").add(keys)
  end)
end

return M
