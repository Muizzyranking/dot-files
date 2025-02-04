return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "prettierd",
        "prettier",
        "sql-formatter",
        "autopep8",
        "flake8",
        "shellcheck",
      })
    end,
  },
}
