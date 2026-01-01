local M = {}

---@class lsp.Opts
---@field enabled? boolean
---@field keys? map.KeymapOpts[]

---@type table<string, lsp.Opts>
M.lsps = {
  lua_ls = {},
  basedpyright = {
    keys = {
      {
        "<leader>ci",
        function()
          vim.lsp.buf.code_action({
            filter = function(a)
              return a.title:find("import") ~= nil and a.kind == "quickfix"
            end,
            apply = true,
          })
        end,
        desc = "Auto import word under cursor",
        icon = { icon = "󰋺 ", color = "blue" },
      },
    },
  },
  biome = {
    keys = {
      {
        "<leader>co",
        Utils.lsp.action["source.organizeImports.biome"],
        desc = "Organize Imports",
        icon = { icon = "󰺲" },
      },
      {
        "<leader>cb",
        Utils.lsp.action["source.fixAll.biome"],
        desc = "Fix all diagnostics (biome)",
        icon = { icon = "󰁨" },
      },
    },
  },
  clangd = {
    keys = {
      { "<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", desc = "Switch between source/header" },
    },
  },
  jsonls = {},
  emmet_language_server = {},
  eslint = {
    keys = {
      {
        "<leader>cu",
        "<cmd>LspEslintFixAll<cr>",
        desc = "Fix all (eslint)",
        icon = { icon = "󰁨 ", color = "red" },
      },
    },
  },
  html = {},
  gopls = {},
  ruff = {
    keys = {
      {
        "<leader>co",
        Utils.lsp.action["source.organizeImports"],
        desc = "Organize Imports",
        icon = { icon = "󰺲" },
      },
      {
        "<leader>cu",
        function()
          local diag = vim.diagnostic.get(Utils.fn.ensure_buf(0))
          local ruff_diags = vim.tbl_filter(function(d)
            return d.source and Utils.fn.evaluate(d.source:lower(), "ruff")
          end, diag)
          if #ruff_diags > 0 then
            Utils.lsp.action["source.fixAll.ruff"]()
          end
        end,
        desc = "Fix all fixable diagnostics",
        icon = { icon = "󰁨 ", color = "red" },
      },
      {
        "<leader>cU",
        function()
          Utils.format({ buf = Utils.fn.ensure_buf(0), formatters = { "ruff_fix" }, timeout_ms = 3000 })
        end,
        desc = "Fix all",
        icon = { icon = "󰁨 ", color = "red" },
      },
    },
  },
  tsgo = {
    enabled = false,
    keys = {
      {
        "<leader>ci",
        function()
          vim.lsp.buf.code_action({
            filter = function(a)
              return a.title:match("Add import from") or a.kind == "quickfix"
            end,
            apply = true,
          })
        end,
        desc = "Add missing imports",
      },
    },
  },
  vtsls = {
    enabled = true,
    keys = {
      {
        "gR",
        function()
          Utils.lsp.execute({
            command = "typescript.findAllFileReferences",
            arguments = { vim.uri_from_bufnr(0) },
            open = true,
          })
        end,
        desc = "File References",
      },
      -- {
      --   "<leader>co",
      --   Utils.lsp.action["source.organizeImports"],
      --   desc = "Organize Imports",
      --   cond = function()
      --     local buf = Utils.ensure_buf(0)
      --     return not vim.b[buf].biome_attached
      --   end,
      --   icon = { icon = "󰺲" },
      -- },
      { "<leader>ci", Utils.lsp.action["source.addMissingImports.ts"], desc = "Add missing imports" },
      { "<leader>cu", Utils.lsp.action["source.removeUnused.ts"], desc = "Remove unused imports" },
      { "<leader>cD", Utils.lsp.action["source.fixAll.ts"], desc = "Fix all diagnostics" },
      {
        "<leader>cV",
        function()
          Utils.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
        end,
        desc = "Select TS workspace version",
      },
    },
  },
}

M.keymaps = {
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
  {
    "<leader>cl",
    function()
      vim.cmd.checkhealth("vim.lsp")
    end,
    desc = "Lsp Info",
    icon = { icon = " ", color = "blue" },
  },
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
          Utils.lsp.restart(client.name)
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
    function()
      local inc_rename = require("inc_rename")
      return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
    end,
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

-- Hooks: run after all configs are loaded
---@class LspHook
---@field priority? number
---@field opts? table
---@field fn fun(opts: table): nil Hook function that receives options

---@type table<string, LspHook>
M.hooks = {
  setup_keymaps = {
    opts = { enabled = true },
    fn = function()
      Utils.lsp.on_attach(function()
        Utils.map.del({ "gra", "grn", "grr", "gri", "grt" }, { mode = "n", lsp = true })
        Utils.map.set(M.keymaps, {})
      end)
    end,
  },
  enable_servers = {
    priority = 10,
    opts = { enabled = true, delay = 0 },
    fn = function(opts)
      vim.defer_fn(function()
        local servers_to_enable = {}
        for server_name, server_opts in pairs(M.lsps) do
          if server_opts.enabled ~= false then
            table.insert(servers_to_enable, server_name)
            if server_opts.keys then
              local server_keys = server_opts.keys
              Utils.map.set(server_keys, { lsp = { name = server_name } })
            end
          end
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
  setup_document_color = {
    opts = { enabled = true },
    fn = function()
      Utils.lsp.on_method("textDocument/documentColor", function(_, buf)
        if vim.lsp.document_color ~= nil then
          vim.lsp.document_color.enable(true, buf)
        end
      end)
    end,
  },
  setup_document_highlight = {
    opts = { enabled = true, delay = 100 },
    fn = function(opts)
      if opts.delay then
        vim.opt.updatetime = opts.delay
      end
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
  setup_folds = {
    opts = { enabled = true },
    fn = function()
      Utils.lsp.on_method("textDocument/foldingRange", function(_, buf)
        local win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_buf(win) == buf then
          vim.wo[win].foldmethod = "expr"
          vim.wo[win].foldexpr = "v:lua.vim.lsp.foldexpr()"
        end
      end)
    end,
  },
  setup_semantic_tokens = {
    opts = { enabled = true, disable_for = { "lua_ls" } },
    fn = function(opts)
      local disable_map = {}
      for _, server in ipairs(opts.disable_for or {}) do
        disable_map[server] = true
      end
      Utils.lsp.on_attach(function(client, _)
        if disable_map[client.name] then
          client.server_capabilities.semanticTokensProvider = nil
        end
      end)
    end,
  },
}

function M.run_hooks()
  table.sort(M.hooks, function(a, b)
    local a_priority = a.priority or 0
    local b_priority = b.priority or 0
    return a_priority > b_priority
  end)

  for name, hook in pairs(M.hooks) do
    local opts = hook.opts or {}
    if opts.enabled ~= false then
      opts.enabled = nil
      local ok, err = pcall(hook.fn, opts)
      if not ok then
        Utils.notify.error(string.format("Hook '%s' failed: %s", name, err), { title = "LSP Hooks" })
      end
    end
  end
end

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
Utils.lsp.setup()
M.run_hooks()

return M
