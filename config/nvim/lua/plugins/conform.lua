return {
  "stevearc/conform.nvim",
  optional = true,
  opts = {
    formatters = {
      -- sql formatter doesnt seem to work unless i do this
      ["sql-formatter"] = {
        command = "/home/muizzyranking/.local/share/nvim/mason/bin/sql-formatter",
      },
      -- use semi standard prettier formatter to format javascript
      ["semi-prettier"] = {
        command = "/home/muizzyranking/.npm-global/bin/prettier-semistandard",
      },
    },
    formatters_by_ft = {
      -- use semi standard prettier formatter to format javascript
      ["javascript"] = { "semi-prettier" },

      ["javascriptreact"] = { { "prettierd", "prettier" } },
      ["typescript"] = { { "prettierd", "prettier" } },
      ["typescriptreact"] = { { "prettierd", "prettier" } },
      ["vue"] = { { "prettierd", "prettier" } },
      ["css"] = { { "prettierd", "prettier" } },
      ["scss"] = { { "prettierd", "prettier" } },
      ["less"] = { { "prettierd", "prettier" } },
      ["html"] = { { "prettierd", "prettier" } },
      ["json"] = { { "prettierd", "prettier" } },
      ["jsonc"] = { { "prettierd", "prettier" } },
      ["yaml"] = { { "prettierd", "prettier" } },
      ["markdown"] = { { "prettierd", "prettier" } },
      ["markdown.mdx"] = { { "prettierd", "prettier" } },
      ["graphql"] = { { "prettierd", "prettier" } },
      ["handlebars"] = { { "prettierd", "prettier" } },

      ["bash"] = { "shfmt" },
      ["sh"] = { "beautysh" },
      ["zsh"] = { "beautysh" },

      ["sql"] = { "sql-formatter" },

      ["python"] = { "autopep8" },
    },
  },
}
