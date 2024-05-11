local servers = {
  "prettierd",
  "prettier",
  "sql-formatter",
  "autopep8",
  "flake8",
  "shellcheck",
}

return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      for _, server in ipairs(servers) do
        table.insert(opts.ensure_installed, server)
      end
    end,
  },
}
