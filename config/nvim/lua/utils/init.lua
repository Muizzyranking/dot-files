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

------------------------------------------------------------------------------
-- Get the foreground color of a highlight group
---@param name string
---@return table?
------------------------------------------------------------------------------
function M.fg(name)
  ---@type {foreground?:number}?
  ---@diagnostic disable-next-line: deprecated
  local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name, link = false })
    ---@diagnostic disable-next-line: deprecated
    or vim.api.nvim_get_hl_by_name(name, true)
  ---@diagnostic disable-next-line: undefined-field
  local fg = hl and (hl.fg or hl.foreground)
  return fg and { fg = string.format("#%06x", fg) } or nil
end

----------------------------------------------------
-- Create an autocommand for LSP attach
---@param on_attach function
----------------------------------------------------
function M.on_attach(on_attach)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buffer = args.buf ---@type number
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      on_attach(client, buffer)
    end,
  })
end

----------------------------------------------------
-- Get a list of active LSP clients
---@param opts table?
---@return lsp.Client[]
----------------------------------------------------
function M.get_clients(opts)
  local ret = {} ---@type lsp.Client[]

  if vim.lsp.get_clients then
    ret = vim.lsp.get_clients(opts)
  else
    ---@diagnostic disable-next-line: deprecated
    ret = vim.lsp.get_active_clients(opts)
    if opts and opts.method then
      ---@param client lsp.Client
      ret = vim.tbl_filter(function(client)
        ---@diagnostic disable-next-line: redundant-parameter
        return client.supports_method(opts.method, { bufnr = opts.bufnr })
      end, ret)
    end
  end

  return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
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

--------------------------
-- Get an upvalue from a function
---@param func function
---@param name string
---@return any
-------------------------------
function M.get_upvalue(func, name)
  local i = 1
  while true do
    local n, v = debug.getupvalue(func, i)
    if not n then
      break
    end
    if n == name then
      return v
    end
    i = i + 1
  end
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

-------------------------------------
-- Lazily require a module and allow direct access to its fields.
---@param require_path string
---@return table
-------------------------------------
M.lazy_require = function(require_path)
  return setmetatable({}, {
    __index = function(_, key)
      return require(require_path)[key]
    end,

    __newindex = function(_, key, value)
      require(require_path)[key] = value
    end,
  })
end

-------------------------------------
-- Get the full path to a file or directory, adjusting for the OS.
---@param root_dir string
---@param value string
---@return string
-------------------------------------
M.get_full_path = function(root_dir, value)
  if vim.loop.os_uname().sysname == "Windows_NT" then
    return root_dir .. "\\" .. value
  end

  return root_dir .. "/" .. value
end

-------------------------------------
-- Check if a given path is a relative path.
---@param path string
---@return boolean
-------------------------------------
M.is_relative_path = function(path)
  return string.sub(path, 1, 1) ~= "/"
end

-------------------------------------
-- Check if the current Neovim instance is running inside a TMUX session.
---@return boolean
-------------------------------------
M.is_in_tmux = function()
  return os.getenv("TMUX") ~= nil
end

-------------------------------------
-- Duplicate the current line.
-------------------------------------
M.duplicate_line = function()
  local current_line = vim.api.nvim_get_current_line() -- Get the current line
  local cursor = vim.api.nvim_win_get_cursor(0) -- Get current cursor position
  vim.api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, { current_line })
  vim.api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] }) -- Move cursor to the duplicated line
end

-------------------------------------
-- Duplicate the currently selected lines in visual mode.
-------------------------------------
M.duplicate_selection = function()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local selected_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, selected_lines)
  local new_cursor_line = math.min(end_line + #selected_lines, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  vim.api.nvim_win_set_cursor(0, { new_cursor_line, 0 })
end

-------------------------------------
-- Remove a buffer, prompting to save changes if the buffer is modified.
---@param buf number|nil
-------------------------------------
M.bufremove = function(buf)
  buf = buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf

  if vim.bo.modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
    if choice == 0 then -- Cancel
      return
    end
    if choice == 1 then -- Yes
      vim.cmd.write()
    end
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
        return
      end
      -- Try using alternate buffer
      local alt = vim.fn.bufnr("#")
      if alt ~= buf and vim.fn.buflisted(alt) == 1 then
        vim.api.nvim_win_set_buf(win, alt)
        return
      end

      -- Try using previous buffer
      ---@diagnostic disable-next-line: param-type-mismatch
      local has_previous = pcall(vim.cmd, "bprevious")
      if has_previous and buf ~= vim.api.nvim_win_get_buf(win) then
        return
      end

      -- Create new listed buffer
      local new_buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_win_set_buf(win, new_buf)
    end)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    ---@diagnostic disable-next-line: param-type-mismatch
    pcall(vim.cmd, "bdelete! " .. buf)
  end
end

return M
