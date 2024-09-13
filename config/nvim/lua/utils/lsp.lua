local M = {}

local utils = require("utils")

M.formatters = {}

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
-- Register a formatter
---@param formatter table The formatter to register
----------------------------------------------------
function M.register(formatter)
  M.formatters[#M.formatters + 1] = formatter
  table.sort(M.formatters, function(a, b)
    return a.priority > b.priority
  end)
end

----------------------------------------------------
-- Format buffer using registered formatters
---@param opts? lsp.Client.format Optional formatting options
----------------------------------------------------
function M.format(opts)
  opts = vim.tbl_deep_extend(
    "force",
    {},
    opts or {},
    M.opts("nvim-lspconfig").format or {},
    M.opts("conform.nvim").format or {}
  )
  local ok, conform = pcall(require, "conform")
  -- use conform for formatting with LSP when available,
  -- since it has better format diffing
  if ok then
    opts.formatters = {}
    conform.format(opts)
  else
    vim.lsp.buf.format(opts)
  end
end

----------------------------------------------------
-- Create a formatter object
---@param opts table? Optional formatter options
---@return table Formatter object
----------------------------------------------------
function M.formatter(opts)
  opts = opts or {}
  local filter = opts.filter or {}
  filter = type(filter) == "string" and { name = filter } or filter
  local ret = {
    name = "LSP",
    primary = true,
    priority = 1,
    format = function(buf)
      M.format(utils.merge({}, filter, { bufnr = buf }))
    end,
    sources = function(buf)
      local clients = M.get_clients(utils.merge({}, filter, { bufnr = buf }))
      ---@param client vim.lsp.Client
      local ret = vim.tbl_filter(function(client)
        return client.supports_method("textDocument/formatting")
          or client.supports_method("textDocument/rangeFormatting")
      end, clients)
      ---@param client vim.lsp.Client
      return vim.tbl_map(function(client)
        return client.name
      end, ret)
    end,
  }
  return utils.merge(ret, opts)
end

----------------------------------------------------
-- Set LSP server keys
---@param server table LSP server configuration
----------------------------------------------------
function M.set_keys(server)
  -- check if server has on_attach
  local original_attach = server.on_attach
  local new_attach = function(client, bufnr)
    if original_attach then
      -- call on acttach if exists
      original_attach(client, bufnr)
    end

    -- set keymaps
    if server.keys then
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
      end
      local keys = server.keys or {}
      for _, mapping in ipairs(keys) do
        local lhs, rhs, opts = mapping[1], mapping[2], mapping[3] or {}
        opts.desc = opts.desc or (server .. " " .. lhs)
        map(lhs, rhs, opts.desc)
      end
    end
  end

  -- replace the on_attach function
  server.on_attach = new_attach
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

return M
