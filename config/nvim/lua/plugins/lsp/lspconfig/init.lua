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
    for type, icon in pairs(Utils.icons.diagnostics) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
    Utils.format.setup()
    Utils.lsp.on_attach(function(client, buffer)
      if not vim.api.nvim_buf_is_valid(buffer) then
        return
      end
      require("plugins.lsp.lspconfig.keymaps").on_attach(client, buffer)
      Utils.lsp.on_support_methods("textDocument/documentHighlight", function()
        if client.server_capabilities.documentHighlightProvider then
          if not vim.api.nvim_buf_is_valid(buffer) then
            return
          end
          local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = true })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = buffer,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = buffer,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
            buffer = buffer,
            callback = function()
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({ group = highlight_augroup })
            end,
          })
        end
      end)
    end)
    Utils.lsp.setup()
    Utils.lsp.on_dynamic_capability(require("plugins.lsp.lspconfig.keymaps").on_attach)

    local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    local has_blink, blink = pcall(require, "blink.cmp")
    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      has_cmp and cmp_nvim_lsp.default_capabilities() or {},
      has_blink and blink.get_lsp_capabilities() or {},
      opts.capabilities or {}
    )

    local function setup(server)
      local server_opts = vim.tbl_deep_extend("force", {
        capabilities = vim.deepcopy(capabilities),
      }, opts.servers[server] or {})

      -- try to get the server config if exists
      -- if not found, then it is a custom server and it is added to lspconfig
      local found, _ = pcall(Utils.lsp.get_config, server)
      if not found then
        if not server_opts and not server_opts.cmd then
          vim.api.nvim_err_writeln(("Missing configuration for server '%s'"):format(server))
          return
        end
        local ok, configs = pcall(require, "lspconfig.configs")
        if not ok then
          return
        end
        local default_config = server_opts
        -- set filetypes to server name if not provided
        if not default_config.filetypes then
          default_config.filetypes = { server }
        end
        configs[server] = {
          default_config = default_config,
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
