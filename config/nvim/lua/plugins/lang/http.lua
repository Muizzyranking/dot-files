return {
  name = "http",
  ft = { "http", "graphql" },
  add_ft = {
    extension = {
      ["http"] = "http",
    },
  },
  lsp = {
    servers = {
      kulala = {},
    },
    setup = {
      kulala = function(_, opts)
        Utils.lsp.on_attach(function(client, _)
          client.server_capabilities =
            vim.tbl_deep_extend("force", client.server_capabilities or {}, opts.capabilities or {})
        end, "kulala")
        -- don't setup with nvim-lspconfig
        return true
      end,
    },
  },
  formatting = {
    format_on_save = true,
    formatters_by_ft = {
      http = { "kulala-fmt" },
    },
  },
  highlighting = {
    parsers = {
      "http",
      "graphql",
    },
  },
  autocmds = {
    {
      callback = function(event)
        local buf = event.buf
        Utils.map.create_abbrevs({
          { "POST", { "post", "Post" } },
          { "GET", { "get", "Get" } },
          { "PATCH", { "patch", "Patch" } },
          { "PUT", { "put", "Put" } },
        }, {
          buffer = buf,
          conds = { "lsp_keyword" },
        })
      end,
    },
  },
  plugins = {
    {
      "mistweaverco/kulala.nvim",
      ft = "http",
      keys = {
        { "<leader>R", "", desc = "+Rest", ft = "http" },
        { "<leader>Rb", "<cmd>lua require('kulala').scratchpad()<cr>", desc = "Open scratchpad", ft = "http" },
        { "<leader>Re", "<cmd>lua require('kulala').set_selected_env()<cr>", desc = "Select Env", ft = "http" },
        { "<leader>Rc", "<cmd>lua require('kulala').copy()<cr>", desc = "Copy as cURL", ft = "http" },
        { "<leader>RC", "<cmd>lua require('kulala').from_curl()<cr>", desc = "Paste from curl", ft = "http" },
        { "<leader>Ri", "<cmd>lua require('kulala').inspect()<cr>", desc = "Inspect current request", ft = "http" },
        { "<leader>Rs", "<cmd>lua require('kulala').run()<cr>", desc = "Send the request", ft = "http" },
        { "<leader>Rq", "<cmd>lua require('kulala').close()<cr>", desc = "Close window", ft = "http" },
        { "<leader>RS", "<cmd>lua require('kulala').show_stats()<cr>", desc = "Show stats", ft = "http" },
        { "<leader>Rt", "<cmd>lua require('kulala').toggle_view()<cr>", desc = "Toggle headers/body", ft = "http" },
        { "<leader>Rp", "<cmd>lua require('kulala').jump_prev()<cr>", desc = "Jump to previous request", ft = "http" },
        { "[r", "<cmd>lua require('kulala').jump_prev()<cr>", desc = "Jump to previous request", ft = "http" },
        { "<leader>Rn", "<cmd>lua require('kulala').jump_next()<cr>", desc = "Jump to next request", ft = "http" },
        { "]r", "<cmd>lua require('kulala').jump_next()<cr>", desc = "Jump to next request", ft = "http" },
      },
      opts = {
        default_view = "headers_body",
        winbar = true,
        icons = {
          inlay = {
            loading = " ",
            done = " ",
            error = " ",
          },
        },
      },
    },
    {
      "folke/which-key.nvim",
      opts = {
        spec = {
          { "<leader>R", group = "Rest", icon = { icon = " ", color = "orange" } },
        },
      },
    },
  },
}
