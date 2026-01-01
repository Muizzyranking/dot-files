---@class utils.fn
local M = {}

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
  if path == "" then
    return false
  end
  local ok, result = pcall(vim.fn.executable, path)
  return ok and result == 1
end

--------------------------------------------------------------
-- Normalize path (handles ~, slashes, and trailing slashes)
---@param path string path to normalize
---------------------------------------------------------------
function M.norm(path)
  if path:sub(1, 1) == "~" then
    local home = vim.uv.os_homedir()
    if home == nil then
      return
    end
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

-----------------------------------------------------------------
--- Normalize a value to ensure it’s always a list.
---@generic T
---@param value T|T[]
---@param resolve? boolean # Whether to resolve functions
---@return T[]
-----------------------------------------------------------------
function M.ensure_list(value, resolve)
  resolve = resolve or false
  if not value then
    return {}
  end
  if resolve and type(value) == "function" then
    value = value()
  end

  return type(value) == "table" and value or { value }
end

----------------------------------------------------------------
--- Ensure a value is a string, converting if necessary.
---@param value any # Input value
---@param default? string # Default value if input is nil or empty
---@return string # The ensured string value
-----------------------------------------------------------------
function M.ensure_string(value, default)
  if not value or value == "" then
    return default or ""
  end
  if type(value) == "function" then
    value = value()
  end
  if type(value) == "table" then
    return table.concat(value, ", ")
  end
  value = type(value) == "string" and value or tostring(value)
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
-- Resolve a boolean value from either a boolean or function
---@param value any # The value to resolve
---@param expected_value? any # Optional value to compare against the resolved result
---@return boolean true if the resolved value is truthy (and matches expected_value if provided)
---------------------------------------------------------------
function M.evaluate(value, expected_value)
  if type(value) == "function" then
    value = value()
  end

  if expected_value ~= nil then
    if type(expected_value) == "function" then
      expected_value = expected_value()
    end
    return value == expected_value
  end

  if type(value) == "table" then
    return next(value) ~= nil
  end
  return not not value
end

---@class RunCmdOpts
---@field input? string
---@field trim? boolean
---@field callback? fun(output: string, success: boolean, exit_code: number)

---@param cmd string|string[]|function
---@param opts RunCmdOpts?
function M.run_command(cmd, opts)
  opts = opts or {}
  if type(cmd) == "function" then
    cmd = cmd()
  end
  if not cmd or cmd == "" then
    return false, "No command provided"
  end
  local ok, output = pcall(vim.fn.system, cmd, opts.input or "")
  local success = vim.v.shell_error == 0 and ok

  if opts.trim then
    output = vim.trim(output)
  end

  if opts.callback then
    if type(opts.callback) == "function" then
      opts.callback(output, success, vim.v.shell_error)
    end
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
  if target_buf == -1 then
    return nil
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == target_buf then
      return win
    end
  end

  return nil
end

---@param option string
---@param value any
---@param buf? number
function M.set_buf_option(option, value, buf)
  buf = M.ensure_buf(buf)
  pcall(function()
    vim.bo[buf][option] = value
  end)
end

function M.is_in_git_repo(notify)
  notify = notify or false
  local success, output = M.run_command({ "git", "rev-parse", "--is-inside-work-tree" }, {
    trim = true,
    callback = function(output, success, _)
      if notify and not success then
        Utils.notify.error("Failed to check git repository: " .. output)
      end
    end,
  })
  return success and output:match("true") ~= nil
end

--- use another filetype config in this filetype
---@param filetype string
function M.ft_config(filetype)
  filetype = "ftplugin/" .. filetype .. ".lua"
  if vim.fn.filereadable(vim.fn.stdpath("config") .. "/" .. filetype) == 1 then
    vim.cmd("runtime " .. filetype)
  end
  Utils.notify.warn("No filetype config found for '" .. filetype .. "'")
end

return M
