---@class utils
---@field actions utils.actions
---@field cmp utils.cmp
---@field color_converter utils.color_converter
---@field format utils.format
---@field icons utils.icons
---@field lsp utils.lsp
---@field lualine utils.lualine
---@field root utils.root
---@field setup_lang utils.setup_lang
---@field telescope utils.telescope
---@field terminal utils.terminal
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

---------------------------------------------------------------
--- Set keymap using which key
---@param mappings utils.maptable[]
---------------------------------------------------------------
function M.map(mappings)
  if type(mappings[1]) ~= "table" then
    mappings = { mappings }
  end
  for _, v in ipairs(mappings) do
    if type(v) ~= "table" then
      error("keys must be an array of arrays")
    end
  end
  local wk_maps = {}
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
      table.insert(wk_maps, {
        lhs,
        mode = mapping.mode or "n",
        icon = mapping.icon,
        desc = mapping.desc or "",
        buffer = mapping.buffer,
      })
    end
  end

  if #wk_maps > 0 and have_wk then
    M.on_load("which-key.nvim", function()
      require("which-key").add(wk_maps)
    end)
  end
end

---------------------------------------------------------------
---@param opts utils.togglemap
---@return table|nil Returns a mapping table if `set_key` is `false`, otherwise sets the keymap and returns `nil`.
---------------------------------------------------------------
function M.toggle_map(opts)
  local mapping = {
    opts[1],
    opts.toggle_fn or function()
      opts.change_state(opts.get_state())
      if opts.notify ~= false then
        Utils.notify[opts.get_state() and "info" or "warn"](
          ("%s %s"):format(opts.get_state() and "Enabled" or "Disabled", opts.name or " "),
          { title = opts.name or "Option" }
        )
      end
    end,
    desc = type(opts.desc) == "function" and function()
      return opts.desc(opts.get_state())
    end or opts.desc or ("Toggle %s"):format(opts.name),
    icon = function()
      local state = opts.get_state()
      local icon = opts.icon or {}
      local color = opts.color or {}
      return {
        icon = state and (icon.enabled or "  ") or (icon.disabled or " "),
        color = state and (color.enabled or "green") or (color.disabled or "yellow"),
      }
    end,
  }
  for k, v in pairs(opts) do
    if mapping[k] == nil then
      mapping[k] = v
    end
  end
  for _, field in ipairs({
    "name",
    "get_state",
    "toggle_fn",
    "change_state",
    "color",
    "notify",
    "set_key",
  }) do
    mapping[field] = nil
  end

  if opts.set_key ~= false then
    M.map(mapping)
    return
  end

  return mapping
end

--------------------------------
-- checks if the current buffer is a notes directory
---@return boolean
--------------------------------
function M.is_in_notes_dir()
  local root = Utils.root.find_pattern_root(0, { ".obsidian" })
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

local cache = {} ---@type table<(fun()), table<string, any>>
---@generic T: fun()
---@param fn T
---@return T
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

return M
