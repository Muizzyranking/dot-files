---@class utils
---@field actions utils.actions
---@field autocmd utils.autocmd
---@field bigfile utils.bigfile
---@field cmp utils.cmp
---@field discipline utils.discipline
---@field format utils.format
---@field git utils.git
---@field hl utils.hl
---@field icons utils.icons
---@field lang utils.lang
---@field lsp utils.lsp
---@field map utils.map
---@field notify utils.notify
---@field plugins utils.plugins
---@field root utils.root
---@field treesitter utils.treesitter
---@field toggle utils.toggle
---@field ui utils.ui
local M = {}

setmetatable(M, {
  __index = function(t, k)
    t[k] = require("utils." .. k)
    return t[k]
  end,
})

M.CONFIG = {
  ignore_buftypes = { "nofile", "terminal", "prompt" },
  ignore_filetypes = {
    "notify",
    "noice",
    "WhichKey",
    "alpha",
    "dashboard",
    "lazy",
    "mason",
    "lspinfo",
    "snacks_picker_list",
    "snacks_picker_input",
    "gitcommit",
    "gitrebase",
    "help",
  },
}

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
  if not plugin then return {} end
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

---------------------------------------------------------------
-- Check if the Neovim is running inside a TMUX session.
---@return boolean
---------------------------------------------------------------
M.is_in_tmux = function()
  return os.getenv("TMUX") ~= nil
end

-------------------------------------
-- Checks if the path is executable
---@param path any
---@return boolean
-------------------------------------
M.is_executable = function(path)
  if path == "" then return false end
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
    if home:sub(-1) == "\\" or home:sub(-1) == "/" then home = home:sub(1, -2) end
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
    if cache[fn][key] == nil then cache[fn][key] = fn(...) end
    return cache[fn][key]
  end
end

-----------------------------------------------------------------
--- Normalize a value to ensure it’s always a list.
---@param value any # Input value
---@param resolve? boolean # Whether to resolve functions
---@return string[]|table # Listified value
-----------------------------------------------------------------
function M.ensure_list(value, resolve)
  resolve = resolve or false
  if not value then return {} end
  if resolve and M.type(value, "function") then value = value() end

  return M.type(value, "table") and value or { value }
end

----------------------------------------------------------------
--- Ensure a value is a string, converting if necessary.
---@param value any # Input value
---@param default? string # Default value if input is nil or empty
---@return string # The ensured string value
-----------------------------------------------------------------
function M.ensure_string(value, default)
  if not value or value == "" then return default or "" end
  if M.type(value, "function") then value = value() end
  if M.type(value, "table") then return table.concat(value, ", ") end
  value = M.type(value, "string") and value or tostring(value)
  return value ~= nil and value or default or ""
end

-----------------------------------------------------------------
--- Ensures a valid buffer number, defaulting to current buffer if none provided
---@param buf? number # The buffer number to validate
---@return number # The validated buffer number
-----------------------------------------------------------------
function M.ensure_buf(buf)
  if not buf or buf == nil or buf == 0 or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_get_current_buf()
  end
  return buf
end

-----------------------------------------------------------------
---@param buf? number # default: current buf
---@return string # filename
-----------------------------------------------------------------
function M.get_filepath(buf)
  buf = M.ensure_buf(buf)
  return vim.api.nvim_buf_get_name(buf)
end

---------------------------------------------------------------
---@param var any
---@param expected_type string
---@return boolean
---------------------------------------------------------------
function M.type(var, expected_type)
  return type(var) == expected_type
end

---------------------------------------------------------------
-- Resolve a boolean value from either a boolean or function
---@param value any # The value to resolve
---@param expected_value? any # Optional value to compare against the resolved result
---@return boolean true if the resolved value is truthy (and matches expected_value if provided)
---------------------------------------------------------------
function M.evaluate(value, expected_value)
  if M.type(value, "function") then value = value() end

  if expected_value ~= nil then
    if M.type(expected_value, "function") then expected_value = expected_value() end
    return value == expected_value
  end

  -- Handle empty tables as falsy
  if M.type(value, "table") then return next(value) ~= nil end

  --  return the truthiness of the resolved value
  return not not value
end

------------------------------------------------------
-- check if a buffer is ignored based on its type
---@param bufnr? number # buffer number to check
---@param buftypes? string[] # list of buffer types to check against
---@param merge? boolean # whether to merge with default ignore list
---@return boolean # true if the buffer type is ignored
------------------------------------------------------
function M.ignore_buftype(bufnr, buftypes, merge)
  buftypes = merge and vim.list_extend(M.CONFIG.ignore_buftypes, M.ensure_list(buftypes))
    or (buftypes or M.CONFIG.ignore_buftypes)
  bufnr = M.ensure_buf(bufnr)
  local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
  if vim.tbl_contains(M.CONFIG.ignore_buftypes, buftype) then return true end

  return false
end

------------------------------------------------------
-- check if a buffre filetype is ignored
---@param bufnr? number # buffer number to check
---@param filetypes? string[] # list of filetypes to check against
---@param merge? boolean # whether to merge with default ignore list
---@return boolean # true if the buffer type is ignored
------------------------------------------------------
function M.ignore_filetype(bufnr, filetypes, merge)
  bufnr = M.ensure_buf(bufnr)
  filetypes = merge and vim.list_extend(M.CONFIG.ignore_filetypes, M.ensure_list(filetypes))
    or (filetypes or M.CONFIG.ignore_filetypes)
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  if vim.tbl_contains(filetypes, filetype) then return true end

  return false
end

---@param cmd string|string[]|function
---@param opts utils.run_command_opts
function M.run_command(cmd, opts)
  opts = opts or {}
  if M.type(cmd, "function") then cmd = cmd() end
  if not cmd or cmd == "" then return false, "No command provided" end
  local ok, output = pcall(vim.fn.system, cmd, opts.input or "")
  local success = vim.v.shell_error == 0 and ok

  if opts.trim then output = vim.trim(output) end

  if opts.callback then
    if M.type(opts.callback, "function") then opts.callback(output, success, vim.v.shell_error) end
  end

  return success, output
end

----------------------------------------------------
--- Find existing window containing the target file
--- @param filename string The file path to search for
--- @return number|nil Window handle if found
----------------------------------------------------
function M.find_win_with_file(filename)
  local target_buf = vim.fn.bufnr(filename)
  if target_buf == -1 then return nil end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == target_buf then return win end
  end

  return nil
end

---@param option string
---@param value any
---@param buf? number
function M.set_buf_option(option, value, buf)
  buf = Utils.ensure_buf(buf)
  pcall(function()
    vim.bo[buf][option] = value
  end)
end

local function _has_kitty_graphics_support(script_path)
  local path = script_path or "check_kitty.py"
  if not M.is_executable(path) then return false end
  local success = M.run_command(path)
  return success
end

M.has_kitty_graphics_support = M.memoize(_has_kitty_graphics_support)()

return M
