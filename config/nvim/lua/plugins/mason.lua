local servers = {
  -- "prettierd",
  -- "prettier",
  "sql-formatter",
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
