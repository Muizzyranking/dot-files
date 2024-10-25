--------------------------
-- Module definition
--------------------------
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
--- Calculate dimensions for a floating window
---@param opts table Options for window dimensions
---@return number, number, number, number - Width, height, row, and column of the window
---------------------------------------------------------------
function M.get_dimensions(opts)
  local width = math.floor(vim.o.columns * (opts.width or 0.9))
  local height = math.floor(vim.o.lines * (opts.height or 0.8))
  local row = math.floor((vim.o.lines - height) / 2) - (opts.row_offset or 1)
  local col = math.floor((vim.o.columns - width) / 2)
  return width, height, row, col
end

---------------------------------------------------------------
--- Create a floating window
---@param buf number Buffer to display in the floating window
---@param opts table Options for the floating window
---@return number Window handle
---------------------------------------------------------------
function M.create_float_window(buf, opts)
  local width, height, row, col = M.get_dimensions(opts)
  local float_opts = {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border or "rounded",
    focusable = true,
  }
  local win = vim.api.nvim_open_win(buf, true, float_opts)
  vim.api.nvim_win_set_option(win, "winblend", opts.winblend or 0)
  return win
end

---------------------------------------------------------------
--- Update the size of an existing window
---@param win number Window handle
---@param opts table Options for window dimensions
---------------------------------------------------------------
function M.update_window_size(win, opts)
  if vim.api.nvim_win_is_valid(win) then
    local width, height, row, col = M.get_dimensions(opts)
    vim.api.nvim_win_set_config(win, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
    })
  end
end

function M.get_highlight_group()
  local hl = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.synID(vim.fn.line("."), vim.fn.col("."), 1)), "name")
  print(hl)
  if hl == "" then
    hl = vim.treesitter.get_captures_at_cursor()[1] or "No highlight group found"
  end
  print(hl)
end

return M
