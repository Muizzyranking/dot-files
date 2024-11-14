---@class utils.lsp
local M = {}

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
-- Format buffer using registered formatters
---@param opts? lsp.Client.format Optional formatting options
----------------------------------------------------
function M.format(opts)
  opts = vim.tbl_deep_extend(
    "force",
    {},
    opts or {},
    Utils.opts("nvim-lspconfig").format or {},
    Utils.opts("conform.nvim").format or {}
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
      M.format(Utils.merge({}, filter, { bufnr = buf }))
    end,
    sources = function(buf)
      local clients = M.get_clients(Utils.merge({}, filter, { bufnr = buf }))
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
  return Utils.merge(ret, opts)
end

----------------------------------------------------
-- Set LSP server keys
---@param server string LSP server configuration
---@param server_opts table LSP server configuration
----------------------------------------------------
function M.set_keys(server, server_opts)
  if server_opts.keys then
    M.on_attach(function(_, buffer)
      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { desc = desc, buffer = buffer })
      end
      for _, key in ipairs(server_opts.keys) do
        local lhs, rhs = key[1], key[2]
        map(lhs, rhs, key.desc)
      end
    end, server)
  end
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

M.cmp = {}

local function snippet_preview(snippet)
  local ok, parsed = pcall(vim.lsp._snippet_grammar.parse, snippet)
  if ok then
    return tostring(parsed)
  else
    return snippet:gsub("%${%d+:(.-)}", "%1"):gsub("%$%d+", ""):gsub("%$0", "")
  end
end

local function snippet_fix(snippet)
  local texts = {}
  return snippet:gsub("%$%b{}", function(m)
    local n, name = m:match("^%${(%d+):(.+)}$")
    if n then
      texts[n] = texts[n] or snippet_preview(name)
      return "${" .. n .. ":" .. texts[n] .. "}"
    end
    return m
  end)
end

local function notify_user(success, msg, snippet)
  local status = success and "warn" or "error"
  Utils.notify[status](
    ([[%s
      ```%s
      %s
      ```]]):format(msg, vim.bo.filetype, snippet),
    { title = "vim.snippet" }
  )
end

function M.cmp.expand_snippet(args)
  local snippet = args.body
  local session = vim.snippet.active() and vim.snippet._session or nil

  -- Attempt to expand the snippet
  local ok, err = pcall(vim.snippet.expand, snippet)

  if not ok then
    -- Try to fix the snippet and expand again if it fails
    local fixed = snippet_fix(snippet)
    ok = pcall(vim.snippet.expand, fixed)
    local msg = ok and "Failed to parse snippet, but was able to fix it automatically."
      or ("Failed to parse snippet.\n" .. err)
    notify_user(ok, msg, snippet)
  end

  -- Restore the original snippet session if necessary
  if session then
    vim.snippet._session = session
  end
end

return M
