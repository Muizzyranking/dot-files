return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      table.insert(opts.ensure_installed, "prettierd")
      table.insert(opts.ensure_installed, "prettier")
      table.insert(opts.ensure_installed, "sql-formatter")

      -- table.insert(opts.ensure_installed, "python-lsp-server")
    end,
  },
}
