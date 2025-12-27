-- plugins/lang/solidity.lua
return {
  name = "solidity",
  ft = "solidity",
  lsp = {
    servers = {
      solidity_ls_nomicfoundation = {
        root_dir = function()
          return vim.fs.dirname(vim.fs.find(".git", { upward = true })[1])
        end,
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
}
