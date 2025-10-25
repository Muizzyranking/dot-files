local M = {}
---@class lsp.KeymapOpts : map.KeymapOpts
---@field has? string|string[] # LSP capability required for this keymap

---@type lsp.KeymapOpts[]?
M._keys = nil
---@type string[]
M.lsp_servers = {}
---@type table<string, lsp.KeymapOpts[]>
M._server_keys = {}

---@return lsp.KeymapOpts[]
function M.get()
  if M._keys then return M._keys end
  M._keys = {
    {
      "gd",
      function()
        Utils.lsp.goto_definition()
      end,
      desc = "Goto Definition",
      has = "definition",
    },
    -- vsplit jump
    {
      "gD",
      function()
        Utils.lsp.goto_definition({ direction = "vsplit" })
      end,
      desc = "Goto Definition (Vsplit)",
      has = "definition",
    },
    {
      "gr",
      function()
        Snacks.picker.lsp_references()
      end,
      nowait = true,
      desc = "References",
    },
    {
      "gT",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "Goto Implementation",
    },
    {
      "<leader>cs",
      function()
        Snacks.picker.lsp_symbols({
          layout = { preset = "code", preview = "main" },
          on_show = function()
            vim.cmd("stopinsert")
          end,
        })
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
    {
      "K",
      function()
        vim.lsp.buf.hover()
      end,
      desc = "Hover",
      has = "hover",
    },
    {
      "]d",
      Utils.lsp.goto_diagnostics(true),
      desc = "Next Diagnostic",
    },
    {
      "[d",
      Utils.lsp.goto_diagnostics(false),
      desc = "Prev Diagnostic",
    },
    {
      "]e",
      Utils.lsp.goto_diagnostics(true, "ERROR"),
      desc = "Next Error",
    },
    {
      "[e",
      Utils.lsp.goto_diagnostics(false, "ERROR"),
      desc = "Prev Error",
    },
    {
      "]w",
      Utils.lsp.goto_diagnostics(true, "WARN"),
      desc = "Next Warning",
    },
    {
      "[w",
      Utils.lsp.goto_diagnostics(false, "WARN"),
      desc = "Prev Warning",
    },
    {
      "gy",
      Utils.lsp.copy_diagnostics,
      desc = "Yank diagnostic message on current line",
      icon = { icon = "󰆏 ", color = "blue" },
      mode = { "n", "x" },
    },
    {
      "<leader>cl",
      "<cmd>LspInfo<cr>",
      desc = "Lsp Info",
      icon = { icon = " ", color = "blue" },
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
    Utils.map.toggle_map({
      "<leader>ui",
      get_state = function(buf)
        return vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
      end,
      change_state = function(state, buf)
        vim.lsp.inlay_hint.enable(not state, { bufnr = buf })
      end,
      name = "Inlay hint",
      has = "inlayHint",
      set_key = false,
    }),
  }

  return M._keys
end

---@param server_name string
---@param keys lsp.KeymapOpts[]
function M.register_keys(server_name, keys)
  M._server_keys[server_name] = keys
end

---@param server_name string
---@return lsp.KeymapOpts[]
function M.get_server_keys(server_name)
  return M._server_keys[server_name] or {}
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
  if ok and config then
    if config.keys then M.register_keys(name, config.keys) end
    M.register_keys(name, config.keys)
    return config.enabled
  elseif not ok then
    Utils.notify.warn(string.format("Failed to load LSP config: %s\n%s", name, config), { title = "LSP Config" })
  end
  return nil
end

---@param path string # Directory path
local function process_lsp_directory(path)
  if vim.fn.isdirectory(path) == 0 then return end

  local lsp_files = vim.fn.readdir(path)

  for _, file in ipairs(lsp_files) do
    if is_lua_file(file) then
      local name = get_server_name(file)
      if name then
        local enabled = load_lsp_file(path .. "/" .. file, name)
        if M.lsp_servers[name] == nil then
          M.lsp_servers[name] = enabled ~= false -- true unless explicitly false
        end
      end
    end
  end
end

function M.load_lsp_configs(dirs)
  local config_path = vim.fn.stdpath("config")
  dirs = dirs or { "/lsp", "/after/lsp" }
  dirs = Utils.ensure_list(dirs, true)

  for _, dir in ipairs(dirs) do
    process_lsp_directory(config_path .. dir)
  end
end

---@type lsp.KeymapOpts[]
local all_keys = {}
function M.on_attach(_, buffer)
  buffer = Utils.ensure_buf(buffer)
  local defaults = { "gra", "grn", "grr", "gri" }
  for _, key in ipairs(defaults) do
    pcall(vim.keymap.del, "n", key, { buffer = buffer })
  end
  local clients = Utils.lsp.get_clients({ bufnr = buffer })
  local keys = vim.tbl_extend("force", {}, M.get())
  for _, client in ipairs(clients) do
    vim.list_extend(keys, M.get_server_keys(client.name))
  end
  all_keys = {}
  for _, key in ipairs(keys) do
    local has = not key.has or Utils.lsp.has(buffer, key.has)
    if has then
      key.has = nil
      key.buffer = buffer
      key.silent = key.silent ~= false
      all_keys[#all_keys + 1] = key
    end
  end
  Utils.map.set_keymaps(all_keys)
end

function M.setup(opts)
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
  Utils.format.setup()
  Utils.lsp.on_attach(function(client, buffer)
    M.on_attach(client, buffer)
  end)
  Utils.lsp.setup()
  Utils.lsp.on_dynamic_capability(function(client, buffer)
    M.on_attach(client, buffer)
  end)
  Utils.lsp.on_support_methods("textDocument/foldingRange", function(_, _)
    local win = vim.api.nvim_get_current_win()
    vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
  end)

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
  M.load_lsp_configs()

  local servers_to_enable = {}
  for server, enabled in pairs(M.lsp_servers) do
    if enabled then table.insert(servers_to_enable, server) end
  end
  if #servers_to_enable > 0 then vim.lsp.enable(servers_to_enable, true) end
end

return M
