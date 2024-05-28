--------------------------
-- Module definition
--------------------------
local M = {}

---------------------------------------------------------------
-- Check if a plugin is installed
---@param plugin string: Name of the plugin
---@return boolean: True if the plugin is enabled, false otherwise
---------------------------------------------------------------
function M.has(plugin)
  return require("lazy.core.config").spec.plugins[plugin] ~= nil
end

------------------------------------------------------------------------------
-- Get the foreground color of a highlight group
---@param name string: Name of the highlight group
---@return table?: A table containing the foreground color value
--                  formatted as a hex string (#RRGGBB) or nil if not found.
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
---@param on_attach function: The function to be called on attach.
--                            This function takes two arguments:
--                            - client: The attached LSP client object.
--                            - buffer: The buffer number where the client attached.
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
---@param opts table?: Optional configuration table.
--                    - method string?: (optional) Filter clients based on a supported method.
--                    - bufnr number?: (optional) Filter clients for a specific buffer.
--                    - filter function?: (optional) Additional filtering function for clients.
---@return lsp.Client[]: An array containing the active LSP client objects.
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
---@param name string: Name of the plugin
---@return table: A table containing the plugin options.
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
---@param func function: The function to get the upvalue from.
---@param name string: Name of the upvalue to retrieve.
---@return any: The value of the upvalue or nil if not found
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

---@param name string
---@param fn fun(name:string)
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

M.get_full_path = function(root_dir, value)
  if vim.loop.os_uname().sysname == "Windows_NT" then
    return root_dir .. "\\" .. value
  end

  return root_dir .. "/" .. value
end

M.is_relative_path = function(path)
  return string.sub(path, 1, 1) ~= "/"
end

-- Function to check if running inside tmux
M.is_in_tmux = function()
  return os.getenv("TMUX") ~= nil
end

return M
