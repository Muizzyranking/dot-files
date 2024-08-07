return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "n",
      desc = "Format buffer",
    },
    {
      "<leader>cF",
      function()
        require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
      end,
      mode = { "n", "v" },
      desc = "Format Injected Langs",
    },
  },
  opts = {
    notify_on_error = true,
    format_on_save = function(bufnr)
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 500, lsp_fallback = true }
    end,
    formatters = {
      djlint = {
        command = "djlint",
        args = function(ctx)
          return {
            "--reformat",
            "-",
            "--indent",
            "2",
          }
        end,
        -- prepend_args = { "--reformat", "--indent=2" },
      },
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
      ["javascript"] = { "semi-prettier" },

      -- ["javascript"] = { { "prettierd", "prettier" } },
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

      ["htmldjango"] = { "djlint" },
      ["bash"] = { "shfmt" },
      ["sh"] = { "shfmt" },
      -- ["zsh"] = { "beautysh" },

      ["sql"] = { "sql-formatter" },
      ["python"] = { "autopep8" },
      -- ["python"] = { "black" },
      ["lua"] = { "stylua" },
    },
  },
}
