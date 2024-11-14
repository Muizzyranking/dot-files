return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sqlls = {},
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = { "sqlfluff" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        sqlfluff = {
          args = { "format", "--dialect=ansi", "-" },
        },
      },
      formatters_by_ft = {
        ["sql"] = { "sqlfluff" },
        ["mysql"] = { "sqlfluff" },
        ["plsql"] = { "sqlfluff" },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "sql",
      },
    },
  },
}
