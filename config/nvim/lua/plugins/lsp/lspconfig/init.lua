return {
  "neovim/nvim-lspconfig",
  event = "LazyFile",
  dependencies = {
    "mason-org/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
  },
  opts = {
    servers = {},
    setup = {},
    capabilities = {
      workspace = {
        fileOperations = {
          didRename = true,
          willRename = true,
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
    local api = vim.api
    local lsp = vim.lsp
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
      if not api.nvim_buf_is_valid(buffer) then
        return
      end
      require("plugins.lsp.lspconfig.keymaps").on_attach(client, buffer, opts)
    end)
    Utils.lsp.setup()
    Utils.lsp.on_dynamic_capability(function(client, buffer)
      require("plugins.lsp.lspconfig.keymaps").on_attach(client, buffer, opts)
    end)

    local has_blink, blink = pcall(require, "blink.cmp")
    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      lsp.protocol.make_client_capabilities(),
      has_blink and blink.get_lsp_capabilities() or {},
      opts.capabilities or {}
    )

    local function setup(server)
      local server_opts = vim.tbl_deep_extend("force", {
        capabilities = vim.deepcopy(capabilities),
      }, opts.servers[server] or {})

      if opts.setup[server] then
        if opts.setup[server](server, server_opts) then
          return
        end
      end
      -- try to get the server config if exists
      -- if not found, then it is a custom server and it is added to lspconfig
      local config_available, config = pcall(Utils.lsp.get_config, server)
      if not config_available or not config.default_config then
        if not opts.servers[server] or not opts.servers[server].cmd then
          Utils.notify.error(("Missing configuration for server '%s'"):format(server))
          return
        end
        if not Utils.is_executable(opts.servers[server].cmd[1]) then
          Utils.notify.error(("Server '%s' is not found"):format(server))
          return
        end
        local ok, configs = pcall(require, "lspconfig.configs")
        if not ok then
          return
        end
        configs[server] = {
          default_config = vim.tbl_extend("keep", opts.servers[server], {
            filetypes = { server },
          }),
        }
      end

      require("lspconfig")[server].setup(server_opts)
    end
    -- get all the servers that are available through mason-lspconfig
    local mason_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
    local all_servers = {}
    if mason_ok then
      all_servers = vim.tbl_keys(require("mason-lspconfig").get_mappings().lspconfig_to_package)
    end

    local ensure_installed = {} ---@type string[]
    for server, server_opts in pairs(opts.servers) do
      if server_opts then
        server_opts = server_opts == true and {} or server_opts

        if server_opts.enabled ~= false then
          if vim.tbl_contains(all_servers, server) then
            ensure_installed[#ensure_installed + 1] = server
          end
          setup(server)
        end
      end
    end

    if mason_ok then
      mason_lspconfig.setup({
        ensure_installed = vim.tbl_deep_extend("force", ensure_installed, {}),
      })
    end
  end,
}
