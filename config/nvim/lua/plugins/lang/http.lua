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
          { "post", "POST" },
          { "get", "GET" },
          { "patch", "PATCH" },
          { "put", "PUT" },
        }, {
          buffer = buf,
          builtin = "lsp_keyword",
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
        { "<leader>Rc", "<cmd>lua require('kulala').copy()<cr>", desc = "Copy as cURL", ft = "http" },
        { "<leader>RC", "<cmd>lua require('kulala').from_curl()<cr>", desc = "Paste from curl", ft = "http" },
        { "<leader>Ri", "<cmd>lua require('kulala').inspect()<cr>", desc = "Inspect current request", ft = "http" },
        { "<leader>Rs", "<cmd>lua require('kulala').run()<cr>", desc = "Send the request", ft = "http" },
        { "<leader>Rq", "<cmd>lua require('kulala').close()<cr>", desc = "Close window", ft = "http" },
        { "<leader>RS", "<cmd>lua require('kulala').show_stats()<cr>", desc = "Show stats", ft = "http" },
        { "<leader>Rt", "<cmd>lua require('kulala').toggle_view()<cr>", desc = "Toggle headers/body", ft = "http" },
        { "<leader>Rp", "<cmd>lua require('kulala').jump_prev()<cr>", desc = "Jump to previous request", ft = "http" },
        { "<leader>[r", "<cmd>lua require('kulala').jump_prev()<cr>", desc = "Jump to previous request", ft = "http" },
        { "<leader>Rn", "<cmd>lua require('kulala').jump_next()<cr>", desc = "Jump to next request", ft = "http" },
        { "<leader>]r", "<cmd>lua require('kulala').jump_next()<cr>", desc = "Jump to next request", ft = "http" },
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
  },
}
