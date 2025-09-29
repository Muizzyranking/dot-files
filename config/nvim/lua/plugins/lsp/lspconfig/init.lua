return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile", "BufWritePre" },
  dependencies = {
    "mason-org/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
  },
  opts = {
    servers = {},
    setup = {},
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
    diagnostics = {
      underline = true,
      update_in_insert = false,
      virtual_text = false,
      float = {
        border = "single",
        source = true,
        max_width = 100,
      },
      severity_sort = true,
    },
  },
  config = function(_, opts)
    local diagnostic = vim.diagnostic
    opts.diagnostics.signs = {
      text = {},
      numhl = {},
    }
    for name, icon in pairs(Utils.icons.diagnostics) do
      local severity = diagnostic.severity[name:upper()]
      opts.diagnostics.signs.text[severity] = icon
      opts.diagnostics.signs.numhl[severity] = "DiagnosticSign" .. name
    end

    diagnostic.config(vim.deepcopy(opts.diagnostics))
    Utils.format.setup()
    Utils.lsp.on_attach(function(client, buffer)
      buffer = Utils.ensure_buf(buffer)
      require("plugins.lsp.lspconfig.keymaps").on_attach(client, buffer, opts)
    end)
    Utils.lsp.setup()
    Utils.lsp.on_dynamic_capability(function(client, buffer)
      require("plugins.lsp.lspconfig.keymaps").on_attach(client, buffer, opts)
    end)

    Utils.lsp.on_support_methods("textDocument/foldingRange", function(_, _)
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
    end)
    if opts.capabilities then vim.lsp.config("*", { capabilities = opts.capabilities }) end

    local function setup(server)
      local server_opts = opts.servers[server] or {}
      if opts.setup[server] then
        if opts.setup[server](server, server_opts) then return true end
      end

      if server_opts.cmd then
        if type(server_opts.cmd) == "table" and not Utils.is_executable(server_opts.cmd[1]) then
          Utils.notify.error(("Server '%s' is not found"):format(server))
          return false
        end
      end

      vim.lsp.config(server, server_opts)
      vim.lsp.enable(server, true)
    end
    -- get all the servers that are available through mason-lspconfig
    local mason_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
    local all_servers = {}
    if mason_ok then
      all_servers = vim.tbl_keys(require("mason-lspconfig").get_mappings().lspconfig_to_package) or {}
    end

    local ensure_installed = {} ---@type string[]
    for server, server_opts in pairs(opts.servers) do
      server_opts = server_opts == true and {} or server_opts
      if server_opts and server_opts.enabled ~= false then
        setup(server)
        if vim.tbl_contains(all_servers, server) and server_opts.mason ~= false then
          ensure_installed[#ensure_installed + 1] = server
        end
      end
    end

    if mason_ok then
      mason_lspconfig.setup({
        ensure_installed = vim.tbl_deep_extend("force", ensure_installed, {}),
        automatic_enable = false,
      })
    end
  end,
}
