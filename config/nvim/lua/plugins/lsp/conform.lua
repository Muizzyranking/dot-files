return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
        end,
        mode = { "n", "v" },
        desc = "Format Injected Langs",
      },
    },
    opts_extend = { "use_prettier" },
    opts = {
      -- since prettier is used for multiple filetypes
      -- this options allows to specify which filetypes to use with prettier
      use_prettier = {},
      notify_on_error = true,
      default_format_opts = {
        timeout_ms = 2500,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
      formatters = {},
      formatters_by_ft = {},
    },
  },
  {
    "stevearc/conform.nvim",
    config = function(_, opts)
      opts.use_prettier = opts.use_prettier or {}
      opts.formatters_by_ft = opts.formatters_by_ft or {}

      for _, ft in ipairs(opts.use_prettier) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "prettierd")
      end
      require("conform").setup(opts)
    end,
  },
}
