return Utils.setup_lang({
  name = "solidity",
  ft = "solidity",
  lsp = {
    servers = {
      solidity_ls_nomicfoundation = {
        root_dir = Utils.on_load("nvim-lspconfig", function()
          require("lspconfig.util").find_git_ancestor()
        end),
      },
    },
  },
  highlighting = {
    parsers = { "solidity" },
  },
  formatting = {
    formatters = {
      prettier_sol = {
        command = "/home/muizzyranking/.npm-global/bin/prettierd",
        args = {
          "--write",
          "--plugin=prettier-plugin-solidity",
          "$FILENAME",
        },
        stdin = false,
      },
    },
    formatters_by_ft = {
      solidity = { "prettier_sol" },
    },
  },
  linting = {
    linters_by_ft = {
      solidity = { "solhint" },
    },
  },
})
