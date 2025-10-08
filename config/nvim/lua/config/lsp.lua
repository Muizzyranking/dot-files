local M = {}
M._keys = nil
M.lsp_servers = {}

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
      Utils.lsp.diagnostic_goto(true),
      desc = "Next Diagnostic",
    },
    {
      "[d",
      Utils.lsp.diagnostic_goto(false),
      desc = "Prev Diagnostic",
    },
    {
      "]e",
      Utils.lsp.diagnostic_goto(true, "ERROR"),
      desc = "Next Error",
    },
    {
      "[e",
      Utils.lsp.diagnostic_goto(false, "ERROR"),
      desc = "Prev Error",
    },
    {
      "]w",
      Utils.lsp.diagnostic_goto(true, "WARN"),
      desc = "Next Warning",
    },
    {
      "[w",
      Utils.lsp.diagnostic_goto(false, "WARN"),
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

local all_keys = {}
function M.on_attach(_, buffer)
  pcall(vim.keymap.del, "n", "gra")
  pcall(vim.keymap.del, "n", "grn")
  pcall(vim.keymap.del, "n", "grr")
  pcall(vim.keymap.del, "n", "gri")
  local clients = Utils.lsp.get_clients({ bufnr = buffer })
  local keys = vim.tbl_extend("force", {}, M.get())
  for _, client in ipairs(clients) do
    local maps = Utils.lsp.get_server_keys(client.name)
    vim.list_extend(keys, maps)
  end
  for _, key in ipairs(keys) do
    local has = not key.has or Utils.lsp.has(buffer, key.has)
    local cond = not key.cond or Utils.evaluate(key.cond, true)
    if has and cond then
      key.has = nil
      key.cond = nil
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
    buffer = Utils.ensure_buf(buffer)
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
          willRenameFiles = true,
          didRenameFiles = true,
          willCreateFiles = true,
          didCreateFiles = true,
          willDeleteFiles = true,
          didDeleteFiles = true,
        },
      },
    },
  })
  local path = vim.fn.stdpath("config") .. "/lsp"

  for _, file in ipairs(vim.fn.readdir(path)) do
    if file:match("%.lua$") then
      local name = file:match("(.+)%.lua$")
      table.insert(M.lsp_servers, name)
    end
  end
  vim.lsp.enable(M.lsp_servers, true)
end

return M
