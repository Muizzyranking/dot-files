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

    local keys = {
      {
        "gd",
        function()
          require("telescope.builtin").lsp_definitions({
            reuse_win = true,
          })
        end,
        desc = "Goto Definition",
        has = "definition",
      },
      {
        "gD",
        function()
          require("telescope.builtin").lsp_definitions({
            jump_type = "vsplit",
          })
        end,
        desc = "Goto Definition (vsplit)",
        has = "definition",
      },
      {
        "g;",
        function()
          vim.lsp.buf.declaration()
        end,
        desc = "Goto Declaration",
        has = "declaration",
      },
      {
        "gr",
        function()
          require("telescope.builtin").lsp_references()
        end,
        desc = "Goto References",
        has = "references",
      },
      {
        "gI",
        function()
          require("telescope.builtin").lsp_implementations()
        end,
        desc = "Goto Implementation",
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
        "<leader>cf",
        function()
          Utils.format.format({ force = true })
        end,
        desc = "Format buffer",
        icon = { icon = " ", color = "green" },
        mode = { "n", "v" },
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
      },
      {
        "<leader>cr",
        vim.lsp.buf.rename,
        desc = "Rename",
        icon = { icon = "󰑕 ", color = "orange" },
        has = "rename",
      },
      {
        "<leader>uh",
        function()
          Utils.lsp.toggle_inlay_hints(0)
        end,
        desc = "Toggle inlay hints",
        icon = function()
          local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
          return enabled and { icon = " ", color = "green" } or { icon = " ", color = "yellow" }
        end,
        has = "inlayHint",
      },
      -- don't really use this
      -- {
      --   "<leader>D",
      --   function()
      --     require("telescope.builtin").lsp_type_definitions()
      --   end,
      --   desc = "Goto References",
      -- },
    }
    local all_keys = {}
    local function key_on_attach(_, buffer)
      local clients = Utils.lsp.get_clients({ bufnr = buffer })
      for _, client in ipairs(clients) do
        local maps = opts.servers[client.name] and opts.servers[client.name].keys or {}
        for _, key in ipairs(maps) do
          table.insert(keys, key)
        end
      end
      for _, key in ipairs(keys) do
        local has = not key.has or Utils.lsp.has(buffer, key.has)
        if has then
          key.has = nil
          key.buffer = buffer
          key.silent = key.silent ~= false
          table.insert(all_keys, key)
        end
      end
      Utils.map(all_keys)
    end

    Utils.lsp.on_attach(function(client, buffer)
      key_on_attach(client, buffer)
      if client.server_capabilities.documentHighlightProvider then
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
      end
    end)
    Utils.lsp.setup()
    Utils.lsp.on_dynamic_capability(key_on_attach)

    vim.api.nvim_create_autocmd("LspDetach", {
      group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
      callback = function()
        vim.lsp.buf.clear_references()
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
