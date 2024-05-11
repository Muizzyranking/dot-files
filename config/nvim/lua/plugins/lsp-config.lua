return {

  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        keys = {
          {
            "<leader>cm",
            "<cmd>Mason<cr>",
            { desc = "Mason" },
          },
        },
      },
      { "folke/neodev.nvim", opts = {} },
      "williamboman/mason-lspconfig.nvim",
      {
        "folke/neoconf.nvim",
        cmd = "Neoconf",
        config = false,
        dependencies = { "nvim-lspconfig" },
      },
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        keys = {
          {
            "<leader>cI",
            "<cmd>MasonToolsInstall<cr>",
            { desc = "Install Missing Servers" },
          },
        },
      },
    },

    config = function()
      local icons = require("config.util").icons.diagnostics
      vim.fn.sign_define("DiagnosticSignError", { text = icons.Error, texthl = "DiagnosticSignError" })
      vim.fn.sign_define("DiagnosticSignWarn", { text = icons.Warn, texthl = "DiagnosticSignWarn" })
      vim.fn.sign_define("DiagnosticSignInfo", { text = icons.Info, texthl = "DiagnosticSignInfo" })
      vim.fn.sign_define("DiagnosticSignHint", { text = icons.Hint, texthl = "DiagnosticSignHint" })

      vim.diagnostic.config({
        underline = true,
        -- virtual_text = { prefix = "", severity = nil, source = "if_many", format = nil },
        signs = true,
        severity_sort = true,
        update_in_insert = true,
      })

      --  This function gets run when an LSP attaches to a particular buffer.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", require("telescope.builtin").lsp_definitions, "Goto Definition")
          -- WARN: This is not Goto Definition, this is Goto Declaration.
          map("gD", vim.lsp.buf.declaration, "Goto Declaration")
          map("gr", require("telescope.builtin").lsp_references, "Goto References")
          map("gI", require("telescope.builtin").lsp_implementations, "Goto Implementation")
          map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type Definition")
          map("K", vim.lsp.buf.hover, "Hover Documentation")
          map("<leader>fs", require("telescope.builtin").lsp_document_symbols, "Document Symbols")
          map("<leader>fS", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace Symbols")
          -- map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
          -- Execute a code action, usually your cursor needs to be on top of an error
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("[d", vim.diagnostic.goto_prev, "Go to previous Diagnostic message")
          map("]d", vim.diagnostic.goto_next, "Go to next Diagnostic message")

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }

      local servers = require("config.servers").lsp
      local fts_n_linters = require("config.servers").fts_n_linters

      require("mason").setup()

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, fts_n_linters)

      require("mason-tool-installer").setup({
        ensure_installed = ensure_installed,
      })

      require("mason-lspconfig").setup({
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for tsserver)
            server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
            require("lspconfig")[server_name].setup(server)
          end,
        },
      })
    end,
  },
}
