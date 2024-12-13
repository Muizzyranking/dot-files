---@class utils
---@field icons utils.icons
---@field keys utils.keys
---@field lsp utils.lsp
---@field cmp utils.cmp
---@field format utils.format
---@field runner utils.runner
---@field terminal utils.terminal
---@field ui utils.ui
---@field lualine utils.lualine
---@field telescope utils.telescope
---@field setup_lang utils.setup_lang
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

----------------------------------------------------
-- Merge multiple tables
--@param ... any Tables to merge
---@return table Merged table
----------------------------------------------------
-- M.merge = "require('lazy.core.util').merge"

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
    Utils.notify.error("Failed to check git repository: " .. (err or "unknown error"))
    return false
  end

  local result = handle:read("*a")
  handle:close()

  if not result then
    Utils.notify.error("Failed to read git command output.")
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
  local path = vim.api.nvim_buf_get_name(buf) or ""
  if path == "" then
    path = vim.uv.cwd() or ""
  else
    -- Resolve the real path and normalize it
    path = vim.uv.fs_realpath(path) or path

    -- Normalize the path (expand ~, replace backslashes, and remove trailing slash)
    ---@diagnostic disable-next-line: param-type-mismatch
    if path:sub(1, 1) == "~" then
      local home = vim.uv.os_homedir()
      if home then
        if home:sub(-1) == "\\" or home:sub(-1) == "/" then
          home = home:sub(1, -2)
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        path = home .. path:sub(2)
      end
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
  return pattern and vim.fs.dirname(pattern)
end

---------------------------------------------------------------
--- Set keymap using which key
---@param mappings MapTable
---------------------------------------------------------------
function M.map(mappings)
  if type(mappings[1]) ~= "table" then
    mappings = { mappings }
  end
  local keys = {}
  local have_wk = M.has("which-key.nvim")

  for _, mapping in ipairs(mappings) do
    local lhs, rhs = mapping[1], mapping[2]
    local opts = {
      desc = type(mapping.desc) == "function" and mapping.desc() or (mapping.desc or ""),
    }
    for _, field in ipairs({ "buffer", "silent", "remap", "expr" }) do
      if mapping[field] ~= nil then
        opts[field] = mapping[field]
      end
    end
    vim.keymap.set(mapping.mode or "n", lhs, rhs, opts)

    if mapping.icon and have_wk then
      keys[#keys + 1] = {
        lhs,
        mode = mapping.mode or "n",
        icon = mapping.icon,
        desc = mapping.desc or "",
        buffer = mapping.buffer,
      }
    end
  end

  if #keys > 0 and have_wk then
    M.on_load("which-key.nvim", function()
      require("which-key").add(keys)
    end)
  end
end

---------------------------------------------------------------
--- create a toggle keymap
---@param opts MapTable
---------------------------------------------------------------
function M.toggle_map(opts)
  local key = opts.key
  local get_state = opts.get_state
  local toggle_fn = opts.toggle_fn
  local icon_enabled = opts.icon_enabled or "  "
  local icon_disabled = opts.icon_disabled or " "
  local color_enabled = opts.color_enabled or "green"
  local color_disabled = opts.color_disabled or "yellow"

  local ret = {
    key,
    toggle_fn,
    desc = "Toggle " .. opts.desc,
    icon = function()
      local state = get_state()
      return {
        icon = state and icon_enabled or icon_disabled,
        color = state and color_enabled or color_disabled,
      }
    end,
  }
  for k, v in pairs(opts) do
    if ret[k] == nil then
      ret[k] = v
    end
  end
  ret.key = nil
  ret.get_state = nil
  ret.toggle_fn = nil
  return ret
end

--------------------------------
-- checks if the current buffer is a notes directory
---@return boolean
--------------------------------
function M.is_in_notes_dir()
  local root = Utils.find_root_directory(0, { ".obsidian" })
  return root ~= nil
end

--------------------------------
-- Get the current word count and character count
--------------------------------
function M.count_words_and_characters()
  local buffer = vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)

  local word_count = 0
  local char_count = 0

  for _, line in ipairs(lines) do
    char_count = char_count + #line

    for _ in string.gmatch(line, "%S+") do --Matches one or more non-whitespace characters
      word_count = word_count + 1
    end
  end

  return { words = word_count, characters = char_count }
end

return M
