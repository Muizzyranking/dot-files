return {
  "neovim/nvim-lspconfig",
  event = "LazyFile",
  dependencies = {
    "mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  opts = {
    servers = {},
    setup = {},
    document_highlight = {
      enabled = true,
    },
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
      if not api.nvim_buf_is_valid(buffer) then
        return
      end
      require("plugins.lsp.lspconfig.keymaps").on_attach(client, buffer, opts)
      Utils.lsp.on_support_methods("textDocument/documentHighlight", function()
        if client.server_capabilities.documentHighlightProvider then
          if not api.nvim_buf_is_valid(buffer) then
            return
          end
          local highlight_augroup = api.nvim_create_augroup("lsp-highlight", { clear = true })
          api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = buffer,
            group = highlight_augroup,
            callback = lsp.buf.document_highlight,
          })
          api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = buffer,
            group = highlight_augroup,
            callback = lsp.buf.clear_references,
          })
          api.nvim_create_autocmd("LspDetach", {
            group = api.nvim_create_augroup("lsp-detach", { clear = true }),
            buffer = buffer,
            callback = function()
              lsp.buf.clear_references()
              api.nvim_clear_autocmds({ group = highlight_augroup })
            end,
          })
        end
      end)
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

      -- try to get the server config if exists
      -- if not found, then it is a custom server and it is added to lspconfig
      local config_available, config = pcall(Utils.lsp.get_config, server)
      if not config_available or not config.default_config then
        if not opts.servers[server] or not opts.servers[server].cmd then
          api.nvim_err_writeln(("Missing configuration for server '%s'"):format(server))
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

      if opts.setup[server] then
        if opts.setup[server](server, server_opts) then
          return
        end
      end

      require("lspconfig")[server].setup(server_opts)
    end
    -- get all the servers that are available through mason-lspconfig
    local mason_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
    local all_servers = {}
    if mason_ok then
      all_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)
    end

    local ensure_installed = {} ---@type string[]
    for server, server_opts in pairs(opts.servers) do
      if server_opts then
        server_opts = server_opts == true and {} or server_opts

        if server_opts.enabled ~= false then
          if not vim.tbl_contains(all_servers, server) then
            setup(server)
          else
            ensure_installed[#ensure_installed + 1] = server
          end
        end
      end
    end

    if mason_ok then
      mason_lspconfig.setup({
        ensure_installed = vim.tbl_deep_extend("force", ensure_installed, {}),
        handlers = { setup },
      })
    end
  end,
}
