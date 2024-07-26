local servers = require("plugins.lsp.servers")
local utils = require("utils")
local lsp_utils = require("utils.lsp")
return {
  {
    {
      "neovim/nvim-lspconfig",
      event = "LazyFile",
      dependencies = {
        "mason.nvim",
        { "folke/neodev.nvim", opts = {} },
        "williamboman/mason-lspconfig.nvim",
        {
          "folke/neoconf.nvim",
          cmd = "Neoconf",
          config = false,
          dependencies = { "nvim-lspconfig" },
        },
      },
      config = function()
        vim.diagnostic.config({
          underline = true,
          -- virtual_text = { prefix = "", severity = nil, source = "if_many", format = nil },
          signs = true,
          severity_sort = true,
          update_in_insert = true,
        })
        --  This function gets run when an LSP attaches to a particular buffer.
        vim.api.nvim_create_autocmd("LspAttach", {
          group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
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
            -- map("<leader>fs", require("telescope.builtin").lsp_document_symbols, "Document Symbols")
            -- map("<leader>fS", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace Symbols")
            -- map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
            map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
            map("[d", vim.diagnostic.goto_prev, "Go to previous Diagnostic message")
            map("]d", vim.diagnostic.goto_next, "Go to next Diagnostic message")

            local diagnostic_goto = function(next, severity)
              local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
              severity = severity and vim.diagnostic.severity[severity] or nil
              return function()
                go({ severity = severity })
              end
            end

            map("]e", diagnostic_goto(true, "ERROR"), "Next Error")
            map("[e", diagnostic_goto(false, "ERROR"), "Prev Error")
            map("]w", diagnostic_goto(true, "WARN"), "Next Warning")
            map("[w", diagnostic_goto(false, "WARN"), "Prev Warning")

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

        local lsps = servers.lsp
        local lsp_servers = vim.tbl_keys(lsps or {})

        require("mason-lspconfig").setup({
          ensure_installed = lsp_servers,
          handlers = {
            function(server_name)
              local server = lsps[server_name] or {}
              -- This handles overriding only values explicitly passed
              -- by the server configuration above. Useful when disabling
              -- certain features of an LSP (for example, turning off formatting for tsserver)
              server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
              require("lspconfig")[server_name].setup(server)
            end,
          },
          ["clangd"] = function()
            local opts = lsps["clangd"]
            opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, opts.capabilities or {})
            if utils.has("clangd_extensions.nvim") then
              local clangd_ext_opts = utils.opts("clangd_extensions.nvim")
              require("clangd_extensions").setup(vim.tbl_deep_extend("force", clangd_ext_opts or {}, { server = opts }))
              return false
            else
              require("lspconfig")["clangd"].setup(opts)
            end
          end,
          ["tsserver"] = function()
            return true
          end,
          ["vtsls"] = function()
            local opts = lsps["vtsls"]
            opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, opts.capabilities or {})
            -- copy typescript settings to javascript
            opts.settings.javascript =
              vim.tbl_deep_extend("force", {}, opts.settings.typescript, opts.settings.javascript or {})
            local plugins = vim.tbl_get(opts.settings, "vtsls", "tsserver")
            if plugins then
              opts.settings.vtsls.tsserver.globalPlugins = vim.tbl_values(plugins)
            end
          end,
          ["eslint"] = function()
            local function get_client(buf)
              return lsp_utils.get_clients({ name = "eslint", bufnr = buf })[1]
            end

            local formatter = lsp_utils.formatter({
              name = "eslint: lsp",
              primary = false,
              priority = 200,
              filter = "eslint",
            })

            -- Use EslintFixAll on Neovim < 0.10.0
            if not pcall(require, "vim.lsp._dynamic") then
              formatter.name = "eslint: EslintFixAll"
              formatter.sources = function(buf)
                local client = get_client(buf)
                return client and { "eslint" } or {}
              end
              formatter.format = function(buf)
                local client = get_client(buf)
                if client then
                  local diag = vim.diagnostic.get(buf, { namespace = vim.lsp.diagnostic.get_namespace(client.id) })
                  if #diag > 0 then
                    vim.cmd("EslintFixAll")
                  end
                end
              end
            end
            lsp_utils.register(formatter)
          end,
        })
      end,
    },
  },
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      ensure_installed = servers.fts_n_linters,
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },
}
