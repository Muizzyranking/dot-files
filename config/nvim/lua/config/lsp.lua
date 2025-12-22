local M = {}
---@type table<string, boolean>
M.lsp_servers = {}
---@type table<string, map.KeymapOpts[]>
M._server_keys = {}

M.keymaps = {
  -- stylua: ignore start
  { "gd", function() Utils.lsp.goto_definition() end, desc = "Goto Definition", has = "definition" },
  -- vsplit jump
  { "gD", function() Utils.lsp.goto_definition({ direction = "vsplit" }) end, desc = "Goto Definition (Vsplit)", has = "definition" },
  { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
  { "gT", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
  {
    "<leader>cs",
    function()
      Snacks.picker.lsp_symbols({ layout = { preset = "code", preview = "main" }, on_show = function() vim.cmd("stopinsert") end })
    end,
    desc = "Lsp Symbols",
    has = "documentSymbol",
  },
  {
    "<leader>sS",
    function()
      Snacks.picker.lsp_workspace_symbols({ filter = Utils.lsp.kind_filter })
    end,
    desc = "LSP Workspace Symbols",
    has = "workspace/symbols",
  },

  -- { "gr", vim.lsp.buf.references, desc = "References" },
  -- { "gI", vim.lsp.buf.implementation, desc = "Goto Implementation" },
  -- { "gT", vim.lsp.buf.type_definition, desc = "Goto Type Definition" },
  -- { "g;", vim.lsp.buf.declaration, desc = "Goto Declaration", has = "declaration" },
  {
    "<c-k>",
    function()
      return vim.lsp.buf.signature_help()
    end,
    desc = "Signature Help",
    has = "signatureHelp",
    mode = "i",
  },
  { "K", function() vim.lsp.buf.hover() end, desc = "Hover", has = "hover" },
  { "]d", Utils.lsp.goto_diagnostics(true), desc = "Next Diagnostic" },
  { "[d", Utils.lsp.goto_diagnostics(false), desc = "Prev Diagnostic" },
  { "]e", Utils.lsp.goto_diagnostics(true, "ERROR"), desc = "Next Error" },
  { "[e", Utils.lsp.goto_diagnostics(false, "ERROR"), desc = "Prev Error" },
  { "]w", Utils.lsp.goto_diagnostics(true, "WARN"), desc = "Next Warning" },
  { "[w", Utils.lsp.goto_diagnostics(false, "WARN"), desc = "Prev Warning" },
  { "]i", Utils.lsp.goto_diagnostics(true, "HINT"), desc = "Next Hint" },
  {
    "gy",
    Utils.lsp.copy_diagnostics,
    desc = "Yank diagnostic message on current line",
    icon = { icon = "󰆏 ", color = "blue" },
    mode = { "n", "x" },
  },
  { "<leader>cl", "<cmd>LspInfo<cr>", desc = "Lsp Info", icon = { icon = " ", color = "blue" } },
  {
    "<leader>cL",
    function()
      local buf = vim.api.nvim_get_current_buf()
      local clients = vim.lsp.get_clients({ bufnr = buf })
      if #clients == 0 then
        Utils.notify.info("No LSP clients attached", { title = "LSP" })
        return
      end
      vim.ui.select(clients, {
        prompt = "Select LSP client to restart:",
        format_item = function(client)
          return client.name
        end,
      }, function(client)
        if client then
          vim.lsp.stop_client(client.id)
          vim.defer_fn(function()
            vim.cmd("edit")
          end, 100)
        end
      end)
    end,
    desc = "Restart LSP",
    icon = { icon = "󰜉 ", color = "orange" },
  },
  {
    "<leader>ca",
    vim.lsp.buf.code_action,
    desc = "Code Action",
    icon = { icon = " ", color = "orange" },
    has = "codeAction",
    mode = { "n", "v" },
  },
  {
    "<leader>cr",
    Utils.lsp.rename,
    desc = "Rename",
    icon = { icon = "󰑕 ", color = "orange" },
    expr = true,
    has = "rename",
    silent = false,
  },
  {
    "<leader>ui",
    get = function(buf)
      return vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
    end,
    set = function(state, buf)
      vim.lsp.inlay_hint.enable(not state, { bufnr = buf })
    end,
    name = "Inlay hint",
    has = "inlayHint",
  },
}
-- stylua: ignore end

---@type table<string, fun(server_name: string, value: any): nil>
M.option_handlers = {
  keys = function(server_name, keys)
    M._server_keys[server_name] = M._server_keys[server_name] or {}
    vim.list_extend(M._server_keys[server_name], keys)
  end,
}

-- Hooks: run after all configs are loaded
---@class LspHook
---@field opts table Whether this hook is enabled
---@field fn fun(opts: table): nil Hook function that receives options

---@type table<string, LspHook>
M.hooks = {
  register_keymaps = {
    opts = { enabled = true },
    fn = function()
      for server_name, keys in pairs(M._server_keys) do
        for _, key in ipairs(keys) do
          local map_opts = vim.tbl_extend("force", {}, key)
          Utils.map.set(map_opts, { lsp = { name = server_name } })
        end
      end
    end,
  },
  enable_servers = {
    opts = { enabled = true, delay = 0 },
    fn = function(opts)
      vim.defer_fn(function()
        local servers_to_enable = {}
        for server, enabled in pairs(M.lsp_servers) do
          if enabled then table.insert(servers_to_enable, server) end
        end

        if #servers_to_enable > 0 then
          local success, err = pcall(vim.lsp.enable, servers_to_enable, true)
          if not success then
            Utils.notify.error("Failed to enable LSP servers: " .. tostring(err), { title = "LSP" })
          end
        end
      end, opts.delay or 0)
    end,
  },
  setup_codelens = {
    opts = { enabled = false, events = { "BufEnter", "CursorHold", "InsertLeave" } },
    fn = function(opts)
      Utils.lsp.on_method("textDocument/codeLens", function(_, buf)
        vim.lsp.codelens.refresh({ bufnr = buf })
        vim.api.nvim_create_autocmd(opts.events, {
          buffer = buf,
          callback = function()
            vim.lsp.codelens.refresh({ bufnr = buf })
          end,
        })
      end)
    end,
  },

  setup_document_highlight = {
    opts = { enabled = true, delay = 100 },
    fn = function(opts)
      if opts.delay then vim.opt.updatetime = opts.delay end
      Utils.lsp.on_method("textDocument/documentHighlight", function(_, buf)
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          buffer = buf,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
          buffer = buf,
          callback = vim.lsp.buf.clear_references,
        })
      end)
    end,
  },
  setup_semantic_tokens = {
    opts = { enabled = false, disable_for = { "lua_ls" } },
    fn = function(opts)
      local disable_map = {}
      for _, server in ipairs(opts.disable_for or {}) do
        disable_map[server] = true
      end
      Utils.lsp.on_attach(function(client, buf)
        if disable_map[client.name] then client.server_capabilities.semanticTokensProvider = nil end
      end)
    end,
  },
}

---@param server_name string
---@param keys map.KeymapOpts[]
function M.register_keys(server_name, keys)
  M._server_keys[server_name] = M._server_keys[server_name] or {}
  vim.list_extend(M._server_keys[server_name], keys)
end

---Check if a file is a Lua file
---@param file string
---@return boolean
local function is_lua_file(file)
  return file:match("%.lua$") ~= nil
end

---Extract LSP server name from filename
---@param file string
---@return string?
local function get_server_name(file)
  return file:match("(.+)%.lua$")
end

---@param path string # Full path to the file
---@param name string # Server name
---@return boolean?
local function load_lsp_file(path, name)
  local ok, config = pcall(dofile, path)
  if not ok then
    Utils.notify.warn(string.format("Failed to load LSP config: %s\n%s", name, config), { title = "LSP Config" })
    return nil
  end
  if not config then return nil end

  for option, handler in pairs(M.option_handlers) do
    if config[option] then handler(name, config[option]) end
  end

  return config.enabled ~= false
end

---Process LSP directory synchronously
---@param path string Directory path
local function process_lsp_directory(path)
  if vim.fn.isdirectory(path) == 0 then return end

  local handle = vim.loop.fs_scandir(path)
  if not handle then return end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end

    if type == "file" and is_lua_file(name) then
      local server_name = get_server_name(name)
      if server_name then
        local enabled = load_lsp_file(path .. "/" .. name, server_name)
        if enabled ~= nil then M.lsp_servers[server_name] = enabled end
      end
    end
  end
end

---Load LSP configs with async processing
function M.load_lsp_configs()
  local config_path = vim.fn.stdpath("config")
  process_lsp_directory(config_path .. "/lsp")
  process_lsp_directory(config_path .. "/after/lsp")
end

local function run_hooks()
  for name, hook in pairs(M.hooks) do
    local opts = hook.opts or {}
    if opts.enabled ~= false then
      opts.enabled = nil
      local ok, err = pcall(hook.fn, opts)
      if not ok then Utils.notify.error(string.format("Hook '%s' failed: %s", name, err), { title = "LSP Hooks" }) end
    end
  end
end

function M.setup()
  vim.diagnostic.config({
    underline = true,
    update_in_insert = false,
    virtual_text = false,
    float = {
      border = "single",
      source = true,
      max_width = 100,
    },
    severity_sort = true,
    signs = (function()
      local signs = { text = {}, numhl = {} }
      for name, icon in pairs(Utils.icons.diagnostics) do
        local severity = vim.diagnostic.severity[name:upper()]
        signs.text[severity] = icon
        signs.numhl[severity] = "DiagnosticSign" .. name
      end
      return signs
    end)(),
  })
  vim.lsp.config("*", {
    capabilities = {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true,
          relativePatternSupport = true,
        },
        fileOperations = {
          didRename = true,
          willRename = true,
        },
      },
    },
  })
  Utils.format.setup()
  Utils.lsp.setup()
  Utils.map.del({ "gra", "grn", "grr", "gri", "grt" }, { mode = "n" })
  Utils.map.set(M.keymaps, {})
  M.load_lsp_configs()
  run_hooks()
end

return M
