return {
  "neovim/nvim-lspconfig",
  event = "LazyFile",
  dependencies = {
    "mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  opts = {
    servers = {
      lua_ls = {
        settings = {
          Lua = {
            cmd = { "lua-language-server" },
            hint = {
              enable = true,
              setType = false,
              paramType = true,
              paramName = "Disable",
              semicolon = "Disable",
              arrayIndex = "Disable",
            },
            codeLens = {
              enable = true,
            },
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = {
                "${3rd}/luv/library",
                unpack(vim.api.nvim_get_runtime_file("", true)),
              },
            },
            completion = {
              callSnippet = "Replace",
            },
          },
        },
      },
    },
    setup = {},
    diagnostics = {
      underline = true,
      update_in_insert = false,
      virtual_text = {
        spacing = 4,
        source = "if_many",
        prefix = "icons",
      },
      float = {
        border = "single",
        source = true,
        max_width = 100,
      },
      severity_sort = true,
    },
  },
  config = function(_, opts)
    if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
      opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
        or function(diagnostic)
          local icons = Utils.icons.diagnostics
          for d, icon in pairs(icons) do
            if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
              return icon
            end
          end
        end
    end
    for type, icon in pairs(Utils.icons.diagnostics) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end
    vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
    --  This function gets run when an LSP attaches to a particular buffer.
    Utils.format.register(Utils.lsp.formatter())
    Utils.format.setup()

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        local buffer = event.buf
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = buffer, desc = "LSP: " .. desc })
        end

        map("gd", function()
          require("telescope.builtin").lsp_definitions()
        end, "Goto Definition")
        map("gD", function()
          require("telescope.builtin").lsp_definitions({
            jump_type = "vsplit",
            reusse_win = true,
          })
        end, "Goto Definition")
        map("g;", vim.lsp.buf.declaration, "Goto Declaration")
        map("gr", require("telescope.builtin").lsp_references, "Goto References")
        map("gI", require("telescope.builtin").lsp_implementations, "Goto Implementation")
        map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type Definition")
        map("K", vim.lsp.buf.hover, "Hover Documentation")

        local diagnostic_goto = function(next, severity)
          local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
          severity = severity and vim.diagnostic.severity[severity] or nil
          return function()
            go({ severity = severity })
          end
        end

        map("]d", diagnostic_goto(true), "Next Diagnostic")
        map("[d", diagnostic_goto(false), "Prev Diagnostic")
        map("]e", diagnostic_goto(true, "ERROR"), "Next Error")
        map("[e", diagnostic_goto(false, "ERROR"), "Prev Error")
        map("]w", diagnostic_goto(true, "WARN"), "Next Warning")
        map("[w", diagnostic_goto(false, "WARN"), "Prev Warning")

        Utils.map({
          {
            "<leader>cf",
            function()
              Utils.format.format({ force = true })
            end,
            desc = "Format buffer",
            icon = { icon = " ", color = "green" },
            buffer = buffer,
            mode = { "n", "v" },
          },
          {
            "<leader>cl",
            "<cmd>LspInfo<cr>",
            desc = "Lsp Info",
            icon = { icon = " ", color = "blue" },
            buffer = buffer,
          },
        })
        if client then
          if client.supports_method(vim.lsp.protocol.Methods.textDocument_codeAction) then
            Utils.map({
              "<leader>ca",
              vim.lsp.buf.code_action,
              desc = "Code Action",
              icon = { icon = " ", color = "orange" },
              buffer = buffer,
            })
          end
          if client.supports_method(vim.lsp.protocol.Methods.textDocument_codeAction) then
            Utils.map({
              "<leader>uh",
              function()
                local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = buffer })
                vim.lsp.inlay_hint.enable(not enabled)
                if enabled then
                  Utils.notify.warn("Inlay Hints disabled", { timeout = 2000, title = "LSP" })
                else
                  Utils.notify.info("Inlay Hints enabled", { timeout = 2000, title = "LSP" })
                end
              end,
              desc = "Toggle inlay hints",
              icon = function()
                local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = buffer })
                return enabled and { icon = " ", color = "green" } or { icon = " ", color = "yellow" }
              end,
              buffer = buffer,
            })
          end
          if client.server_capabilities.documentHighlightProvider then
            local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
              callback = function(ev)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = ev.buf })
              end,
            })
          end
        end
      end,
    })

    local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      has_cmp and cmp_nvim_lsp.default_capabilities() or {},
      opts.capabilities or {}
    )

    require("mason-lspconfig").setup({
      ensure_installed = vim.tbl_keys(opts.servers or {}),
      handlers = {
        function(server)
          local server_opts = opts.servers[server] or {}
          server_opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_opts.capabilities or {})

          if opts.setup[server] then
            if opts.setup[server](server, server_opts) then
              return
            end
          end

          if server_opts.keys then
            Utils.lsp.set_keys(server, server_opts)
          end

          require("lspconfig")[server].setup(server_opts)
        end,
      },
    })
  end,
}
