---@class utils.lsp
---@field breadcrumb utils.lsp.breadcrumb
local M = {}

setmetatable(M, {
  __index = function(t, k)
    t[k] = require("utils.lsp." .. k)
    return t[k]
  end,
})

local notify = Utils.notify.create({ title = "LSP" })

---@class lsp.keymap.Handler
---@field filter vim.lsp.get_clients.Filter
---@field callback fun(client: vim.lsp.Client, buffer: number)
---@field done table<string, boolean> -- tracks which buf:client combos have been handled

local _handlers = {} ---@type lsp.keymap.Handler[]
local did_setup = false

---------------------------------------------------------------
---Normalize LSP method names (add textDocument/ prefix if needed)
---@param method string
---@return string
---------------------------------------------------------------
local function normalize_method(method)
  return method:find("/") and method or ("textDocument/" .. method)
end

---------------------------------------------------------------
---Check if buffer has LSP client matching filter with capability
---@param buf number
---@param client vim.lsp.Client
---@param filter vim.lsp.get_clients.Filter
---@return boolean
---------------------------------------------------------------
local function matches_filter(buf, client, filter)
  if filter.id and client.id ~= filter.id then return false end
  if filter.name and client.name ~= filter.name then return false end
  if filter.bufnr and buf ~= filter.bufnr then return false end

  if filter.method then
    local method = normalize_method(filter.method)
    if not client.supports_method or not client.supports_method(method, { bufnr = buf }) then return false end
  end

  return true
end

---------------------------------------------------------------
---Handle LSP callback execution for matching clients
---@param filter vim.lsp.get_clients.Filter
---------------------------------------------------------------
local function handle(filter)
  local handlers = vim.tbl_filter(function(h)
    for k, v in pairs(filter) do
      if h.filter[k] ~= nil and h.filter[k] ~= v then return false end
    end
    return true
  end, _handlers)

  if #handlers == 0 then return end

  for _, state in ipairs(handlers) do
    local f = vim.tbl_extend("force", vim.deepcopy(state.filter), filter)
    local clients = Utils.lsp.get_clients(f)

    for _, client in ipairs(clients) do
      for buf in pairs(client.attached_buffers) do
        local key = string.format("%d:%d", client.id, buf)

        if not state.done[key] and matches_filter(buf, client, state.filter) then
          state.done[key] = true

          local ok, err = pcall(state.callback, client, buf)
          if not ok then
            notify.error(string.format("LSP callback error for %s (buf %d): %s", client.name, buf, err))
          end
        end
      end
    end
  end
end

---------------------------------------------------------------
---Setup LSP keymap handlers (autocmds for attach/detach)
---------------------------------------------------------------
function M.setup()
  Utils.lsp.breadcrumb.setup()
  if did_setup then return end
  did_setup = true

  Utils.autocmd.autocmd_augroup("utils.lsp.setup", {
    {
      events = { "LspAttach" },
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then return end

        vim.schedule(function()
          handle({ id = ev.data.client_id, bufnr = ev.buf })
        end)
      end,
    },
    {
      events = { "LspDetach" },
      callback = function(ev)
        local key = string.format("%d:%d", ev.data.client_id, ev.buf)
        for _, state in ipairs(_handlers) do
          state.done[key] = nil
        end
      end,
    },
  })
end

---------------------------------------------------------------
--- Register a callback to be executed when LSP client matches filter
--- This is the core function that replaces on_attach, on_support_methods, etc.
---@param filter vim.lsp.get_clients.Filter Filter can include:
---  - id: client id
---  - name: client name
---  - bufnr: buffer number
---  - method: LSP method (e.g., "textDocument/formatting", "formatting", "hover")
---@param callback fun(client: vim.lsp.Client, buffer: number)
---
--- Examples:
---   Utils.lsp.on({}, callback) -- on any LSP attach
---   Utils.lsp.on({ name = "lua_ls" }, callback) -- on lua_ls attach
---   Utils.lsp.on({ method = "formatting" }, callback) -- when formatting is supported
--- Register a callback to be executed when LSP client matches filter
---------------------------------------------------------------
function M.on(filter, callback)
  M.setup()
  if filter.method then
    filter = vim.deepcopy(filter)
    filter.method = normalize_method(filter.method)
  end
  table.insert(_handlers, {
    filter = filter,
    callback = callback,
    done = {},
  })

  local clients = Utils.lsp.get_clients(filter)
  if #clients > 0 then handle(filter) end
end

function M.on_attach(callback)
  M.on({}, callback)
end

---------------------------------------------------------------
---Register callback for a specific LSP server
---@param server_name string
---@param callback fun(client: vim.lsp.Client, buffer: number)
---------------------------------------------------------------
function M.on_server(server_name, callback)
  M.on({ name = server_name }, callback)
end

---------------------------------------------------------------
---Register callback for a specific LSP method/capability
---@param method string LSP method (e.g., "formatting", "hover", "codeAction")
---@param callback fun(client: vim.lsp.Client, buffer: number)
---------------------------------------------------------------
function M.on_method(method, callback)
  M.on({ method = method }, callback)
end

----------------------------------------------------
-- Get a list of active LSP clients
---@param opts table?
---@return lsp.Client[]
----------------------------------------------------
function M.get_clients(opts)
  local ret = {} ---@type lsp.Client[]
  if vim.lsp.get_clients then ret = vim.lsp.get_clients(opts) end
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
--- Check if a specific LSP method is supported
--- @param buffer number Buffer number
--- @param method string|string[] LSP method or array of methods to check
--- @return boolean Whether the method(s) is supported
----------------------------------------------------
function M.has(buffer, method)
  if not buffer or not method then return false end
  if Utils.type(method, "table") then
    for _, m in ipairs(method) do
      if M.has(buffer, m) then return true end
    end
    return false
  end
  if type(method) ~= "string" then return false end

  local clients = M.get_clients({ bufnr = buffer })
  if not clients or #clients == 0 then return false end
  local capability_name = method .. "Provider"
  for _, client in ipairs(clients) do
    if client and client.server_capabilities then
      local capability = client.server_capabilities[capability_name]
      if capability ~= nil and capability ~= false then return true end
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
function M.goto_diagnostics(next, severity)
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
    notify.warn("No diagnostics found in current line")
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
    notify(string.format([[ yanked diagnostic message '%s']], msg))
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

---@param name string
---@return boolean
function M.server_is_valid(name)
  if vim.lsp.config[name] == nil then
    notify.warn(string.format("Server '%s' is not valid", name))
    return false
  end
  return true
end

---@param name string
---@return boolean
function M.stop(name)
  if not M.server_is_valid(name) then return false end
  local success, err = pcall(function()
    vim.cmd.LspStop(name)
  end)

  if not success then
    notify.error(string.format("Failed to stop server '%s': %s", name, err))
    return false
  end
  return true
end

---@param name string
---@return boolean
function M.start(name)
  if not M.server_is_valid(name) then return false end

  local success, err = pcall(function()
    vim.cmd.LspStart(name)
  end)

  if not success then
    notify.error(string.format("Failed to start server '%s': %s", name, err))
    return false
  end
  return true
end

---@param name string
---@return boolean
function M.restart(name)
  if not M.server_is_valid(name) then return false end

  if not M.stop(name) then return false end

  vim.defer_fn(function()
    M.start(name)
  end, 500)

  return true
end

----------------------------------------------------
--- Go to first definition with window reuse and split options
--- @param opts? table Optional parameters
---   - reuse_win: boolean - Whether to reuse existing windows (default: true)
---   - direction: string - "vsplit" or "split" to open in a new split
----------------------------------------------------
function M.goto_definition(opts)
  opts = opts or {}
  local direction = opts.direction
  local reuse_win = opts.reuse_win ~= false

  vim.lsp.buf.definition({
    on_list = function(list_opts)
      local items = list_opts.items
      if not items or #items == 0 then
        notify.warn("No definition found")
        return
      end

      -- Get the first definition
      local item = items[1]
      local filename = item.filename
      local lnum = item.lnum
      local col = item.col

      if not filename then
        notify.error("Invalid definition result: no filename")
        return
      end

      -- Mark current position for jump list
      vim.cmd("normal! m'")

      if direction then
        local cmd = vim.tbl_contains({ "vsplit", "split" }, direction) and direction or "vsplit"
        vim.cmd(cmd .. " " .. vim.fn.fnameescape(filename))
        if lnum then
          col = (col - 1) or 0
          vim.cmd(string.format("normal! %dG%d|", lnum, col + 1))
        end
      elseif reuse_win then
        local current_buf = vim.api.nvim_get_current_buf()
        local current_filename = vim.api.nvim_buf_get_name(current_buf)

        if current_filename == filename then
          vim.cmd(string.format("normal! %dG%d|", lnum, col))
        else
          local existing_win = Utils.find_win_with_file(filename)
          if existing_win then
            vim.api.nvim_set_current_win(existing_win)
            pcall(vim.api.nvim_win_set_cursor, existing_win, { lnum, col - 1 }) -- 0-indexed
          else
            vim.cmd("edit " .. filename)
            pcall(vim.api.nvim_win_set_cursor, 0, { lnum, col - 1 })
          end
        end
      else
        vim.cmd("edit " .. filename)
        pcall(vim.api.nvim_win_set_cursor, 0, { lnum, col - 1 })
      end

      vim.cmd("normal! zz")

      if #items > 1 then notify(string.format("Jumped to first definition (found %d total)", #items)) end
    end,
  })
end

---------------------------------------------------------------
---Prepare keymap options for buffer-local LSP keymap
---@param mapping map.KeymapOpts Original mapping with LSP fields
---@param buf number Buffer number
---@return map.KeymapOpts? opts Returns nil if keymap shouldn't be set
---------------------------------------------------------------
function M.map(mapping, buf)
  local enabled = true
  if type(mapping.enabled) == "function" then
    enabled = mapping.enabled(buf)
  elseif mapping.enabled ~= nil then
    enabled = mapping.enabled
  end
  if not enabled then return nil end
  if mapping.has then
    local methods = type(mapping.has) == "string" and { mapping.has } or mapping.has
    local has_capability = false
    for _, method in ipairs(methods) do
      if M.has(buf, method) then
        has_capability = true
        break
      end
    end
    if not has_capability then return nil end
  end
  local opts = vim.tbl_extend("force", {}, mapping)
  opts.buffer = buf
  opts.lsp = nil
  opts.has = nil
  opts.enabled = nil

  return opts
end

return M
