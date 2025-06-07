---@class utils.lsp
local M = {}

--- Table to track supported methods for LSP clients
M._supports_method = {}

----------------------------------------------------
--- Set up custom LSP handler for dynamic capability registration
--- Overrides the default client/registerCapability handler to trigger a User event
--- when new capabilities are registered for a client
----------------------------------------------------
function M.setup()
  local register_capability = vim.lsp.handlers["client/registerCapability"]
  vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
    ---@diagnostic disable-next-line: no-unknown
    local ret = register_capability(err, res, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client then
      for buffer in pairs(client.attached_buffers) do
        Utils.autocmd.exec_user_event("LspDynamicCapability", {
          data = { client_id = client.id, buffer = buffer },
        })
      end
    end
    return ret
  end
  M.on_attach(M._check_methods)
  M.on_dynamic_capability(M._check_methods)
end

----------------------------------------------------
--- Register a callback for a specific LSP method support
--- @param method string The LSP method to check support for
--- @param fn function Callback function to execute when method is supported
--- @return number Autocmd ID
----------------------------------------------------
function M.on_support_methods(method, fn)
  M._supports_method[method] = M._supports_method[method] or setmetatable({}, { __mode = "k" })

  return Utils.autocmd.on_user_event("LspSupportsMethod", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type number
      if client and method == args.data.method then
        return fn(client, buffer)
      end
    end,
  })
end

----------------------------------------------------
--- Create an autocmd for handling dynamic LSP capabilities
--- @param fn function Callback function to execute when a dynamic capability is detected
--- @param opts? table Optional configuration for the autocmd
--- @return number Autocmd ID
----------------------------------------------------
function M.on_dynamic_capability(fn, opts)
  return Utils.autocmd.on_user_event("LspDynamicCapability", {
    pattern = "LspDynamicCapability",
    group = opts and opts.group or nil,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local buffer = args.data.buffer ---@type number
      if client then
        return fn(client, buffer)
      end
    end,
  })
end

----------------------------------------------------
--- Internal method to check and track supported LSP methods for clients
--- @param client vim.lsp.Client The LSP client
--- @param buffer number The buffer number
----------------------------------------------------
function M._check_methods(client, buffer)
  -- don't trigger on invalid buffers
  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end
  -- don't trigger on non-listed buffers
  if not vim.bo[buffer].buflisted then
    return
  end
  -- don't trigger on nofile buffers
  if vim.bo[buffer].buftype == "nofile" then
    return
  end
  for method, clients in pairs(M._supports_method) do
    clients[client] = clients[client] or {}
    if not clients[client][buffer] then
      if client.supports_method and client.supports_method(method, { bufnr = buffer }) then
        clients[client][buffer] = true

        Utils.autocmd.exec_user_event("LspSupportsMethod", {
          data = { client_id = client.id, buffer = buffer, method = method },
        })
      end
    end
  end
end
----------------------------------------------------
-- Create auto command for LSP attach
---@param on_attach fun(client:vim.lsp.Client, buffer)
---@param name? string
----------------------------------------------------
function M.on_attach(on_attach, name)
  return vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buffer = args.buf ---@type number
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and (not name or client.name == name) then
        return on_attach(client, buffer)
      end
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
  end
  return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end

----------------------------------------------------
-- Execute LSP command
---@param opts LspCommand Options for the LSP command
----------------------------------------------------
function M.execute(opts)
  local params = {
    command = opts.command,
    arguments = opts.arguments,
  }
  if opts.open then
    require("trouble").open({
      mode = "lsp_command",
      params = params,
    })
  else
    return vim.lsp.buf_request(0, "workspace/executeCommand", params, opts.handler)
  end
end

----------------------------------------------------
-- Action metatable for LSP code actions
---@return table Metatable for LSP code actions
----------------------------------------------------
M.action = setmetatable({}, {
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { action },
          diagnostics = {},
        },
      })
    end
  end,
})

----------------------------------------------------
--- Get the configuration for a specific LSP server
--- @param server string Name of the LSP server
--- @return table LSP server configuration
----------------------------------------------------
function M.get_config(server)
  local ok, ret = pcall(require, "lspconfig.configs." .. server)
  if ok then
    return ret
  end
  return require("lspconfig.server_configurations." .. server)
end

----------------------------------------------------
--- Check if a specific LSP method is supported
--- @param buffer number Buffer number
--- @param method string|string[] LSP method or array of methods to check
--- @return boolean Whether the method(s) is supported
----------------------------------------------------
function M.has(buffer, method)
  -- Return false early for invalid inputs
  if not buffer or not method then
    return false
  end

  -- Handle case where method is a table (array) of methods
  if type(method) == "table" then
    for _, m in ipairs(method) do
      if M.has(buffer, m) then
        return true
      end
    end
    return false
  end

  -- Ensure method is a string
  if type(method) ~= "string" then
    return false
  end

  -- Get clients for the buffer
  local clients = M.get_clients({ bufnr = buffer })
  if not clients or #clients == 0 then
    return false
  end

  -- Derive capability name directly by appending "Provider"
  local capability_name = method .. "Provider"

  -- Check if any client has the capability
  for _, client in ipairs(clients) do
    if client and client.server_capabilities then
      local capability = client.server_capabilities[capability_name]

      -- A capability might be boolean, or an object with configuration
      if capability ~= nil and capability ~= false then
        return true
      end
    end
  end

  return false
end

----------------------------------------------------
--- Navigate to next or previous diagnostic
--- @param next boolean Whether to go to next (true) or previous (false) diagnostic
--- @param severity? string Diagnostic severity level
--- @return function Diagnostic navigation function
----------------------------------------------------
function M.diagnostic_goto(next, severity)
  local count = next and 1 or -1
  severity = severity and vim.diagnostic.severity[severity:upper()] or nil

  return function()
    vim.diagnostic.jump({
      count = count,
      severity = severity,
    })
  end
end

-- rename a variable under the cursoe using inc-rename or in built LSP
function M.rename()
  if Utils.has("inc-rename.nvim") then
    local ok, _ = pcall(require, "inc_rename")
    if ok then
      vim.cmd("nohlsearch")
      return ":IncRename " .. vim.fn.expand("<cword>")
    end
  end
  vim.lsp.buf.rename()
end

-----------------------------------------------
-- copy the diagnostic message under the cursor
-----------------------------------------------
function M.copy_diagnostics()
  local diags = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
  if #diags == 0 then
    Utils.notify.warn("[LSP] no diagnostics found in current line")
    return
  end

  ---@param msg string
  local function _yank(msg)
    vim.fn.setreg('"', msg)
    vim.fn.setreg(vim.v.register, msg)
  end

  if #diags == 1 then
    local msg = diags[1].message
    _yank(msg)
    Utils.notify(string.format([[[LSP] yanked diagnostic message '%s']], msg))
    return
  end

  vim.ui.select(
    vim.tbl_map(function(d)
      return d.message
    end, diags),
    { prompt = "Select diagnostic message to yank: " },
    _yank
  )
end

function M.server_is_valid(name)
  if vim.lsp.config[name] == nil then
    Utils.notify.warn(string.format("[LSP] server '%s' is not valid", name))
    return false
  end
  return true
end

function M.stop(name)
  if M.server_is_valid(name) then
    if vim.cmd.LspStop(name) then
      return true
    end
  end
  return false
end

function M.start(name)
  if M.server_is_valid(name) then
    if vim.cmd.LspStart(name) then
      return true
    end
  end
  return false
end

function M.restart(name)
  if M.server_is_valid(name) then
    M.stop(name)
    local timer = assert(vim.uv.new_timer())
    timer:start(500, 0, function()
      vim.schedule_wrap(function()
        M.start(name)
      end)()
    end)
    return true
  end
  return false
end

return M
