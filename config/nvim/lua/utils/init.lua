---@class utils
---@field actions utils.actions
---@field autocmd utils.autocmd
---@field bigfile utils.bigfile
---@field cmp utils.cmp
---@field discipline utils.discipline
---@field folds utils.folds
---@field format utils.format
---@field hl utils.hl
---@field icons utils.icons
---@field lsp utils.lsp
---@field lualine utils.lualine
---@field map utils.map
---@field notify utils.notify
---@field root utils.root
---@field setup_lang utils.setup_lang
---@field smart_nav utils.smart_nav
---@field snacks utils.snacks
---@field word_cycle utils.word_cycle
---@field treesitter utils.treesitter
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

---------------------------------------------------------------
-- Check if is a git repo.
---@return boolean
---------------------------------------------------------------
function M.is_in_git_repo(notify)
  notify = notify or false
  local success, output = M.run_command({ "git", "rev-parse", "--is-inside-work-tree" }, {
    trim = true,
    callback = function(output, success, _)
      if notify and not success then M.notify.error("Failed to check git repository: " .. output) end
    end,
  })
  return success and output:match("true") ~= nil
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
---@return string[]|table # Listified value
-----------------------------------------------------------------
function M.ensure_list(value)
  if not value then return {} end
  if M.type(value, "function") then value = value() end

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
  return M.type(value, "string") and value or tostring(value)
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
function M.get_filename(buf)
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
---@return boolean # true if the buffer type is ignored
------------------------------------------------------
function M.ignore_buftype(bufnr)
  bufnr = M.ensure_buf(bufnr)
  local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
  if vim.tbl_contains(M.CONFIG.ignore_buftypes, buftype) then return true end

  return false
end

------------------------------------------------------
-- check if a buffre filetype is ignored
---@param bufnr? number # buffer number to check
---@return boolean # true if the buffer type is ignored
------------------------------------------------------
function M.ignore_filetype(bufnr)
  bufnr = M.ensure_buf(bufnr)
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  if vim.tbl_contains(M.CONFIG.ignore_filetypes, filetype) then return true end

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
--- Open file in split based on direction
--- @param direction "vsplit"|"split" Direction to open the file
--- @param filename string File path to open
--- @param line number Line number to jump to
--- @param col number Column number to jump to
----------------------------------------------------
function M.open_in_split(direction, filename, line, col)
  local cmd = vim.tbl_contains({ "vsplit", "split" }, direction) and direction or "vsplit"
  vim.cmd(cmd .. " " .. vim.fn.fnameescape(filename))
  if line then
    col = col or 0
    vim.cmd(string.format("normal! %dG%d|", line, col + 1))
  end
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

return M
