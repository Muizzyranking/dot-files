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
        vim.api.nvim_exec_autocmds("User", {
          pattern = "LspDynamicCapability",
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
  return vim.api.nvim_create_autocmd("User", {
    pattern = "LspSupportsMethod",
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
  return vim.api.nvim_create_autocmd("User", {
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
        vim.api.nvim_exec_autocmds("User", {
          pattern = "LspSupportsMethod",
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
  else
    ret = vim.lsp.get_active_clients(opts)
    if opts and opts.method then
      ---@param client lsp.Client
      ret = vim.tbl_filter(function(client)
        return client.supports_method(opts.method, { bufnr = opts.bufnr })
      end, ret)
    end
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
--- Lets LSP clients know that a file has been renamed
---@param from string
---@param to string
---@param rename? fun()
----------------------------------------------------
function M.on_rename_file(from, to, rename)
  local changes = {
    files = {
      {
        oldUri = vim.uri_from_fname(from),
        newUri = vim.uri_from_fname(to),
      },
    },
  }

  local clients = (vim.lsp.get_clients or vim.lsp.get_active_clients)()
  for _, client in ipairs(clients) do
    if client.supports_method("workspace/willRenameFiles") then
      local resp = client.request_sync("workspace/willRenameFiles", changes, 1000, 0)
      if resp and resp.result ~= nil then
        vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
      end
    end
  end

  if rename then
    rename()
  end

  for _, client in ipairs(clients) do
    if client.supports_method("workspace/didRenameFiles") then
      client.notify("workspace/didRenameFiles", changes)
    end
  end
end

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
  if type(method) == "table" then
    for _, m in ipairs(method) do
      if M.has(buffer, m) then
        return true
      end
    end
    return false
  end
  method = method:find("/") and method or "textDocument/" .. method
  local clients = M.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    if client.supports_method(method) then
      return true
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
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end

-- rename a variable under the cursoe using inc-rename or in built LSP
function M.rename()
  if Utils.has("inc-rename.nvim") then
    -- clearing highlight before renaming with inc rename
    -- I get unexplainable issues when renaming with search highlights
    vim.cmd("nohlsearch")
    return ":IncRename " .. vim.fn.expand("<cword>")
  end
  vim.lsp.buf.rename()
end

function M.available_code_actions()
  local params = vim.lsp.util.make_range_params()
  params.context = {
    diagnostics = vim.lsp.diagnostic.get_line_diagnostics(),
    only = { "quickfix", "refactor", "source" },
  }

  vim.lsp.buf_request(0, "textDocument/codeAction", params, function(err, results, ctx, config)
    if err then
      print("Error: " .. vim.inspect(err))
      return
    end
    if not results or vim.tbl_isempty(results) then
      print("No code actions available")
      return
    end
    print("Available actions: " .. vim.inspect(results))
  end)
end

return M
