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
      },
      ["sql-formatter"] = {
        command = "/home/muizzyranking/.local/share/nvim/mason/bin/sql-formatter",
      },
    },
    formatters_by_ft = {
      ["javascript"] = { "prettierd", "prettier" },
      ["javascriptreact"] = { "prettierd", "prettier" },
      ["typescript"] = { "prettierd", "prettier" },
      ["typescriptreact"] = { "prettierd", "prettier" },
      ["vue"] = { "prettierd", "prettier" },
      ["css"] = { "prettierd", "prettier" },
      ["scss"] = { "prettierd", "prettier" },
      ["less"] = { "prettierd", "prettier" },
      ["html"] = { "prettierd", "prettier" },
      ["json"] = { "jq" },
      ["jsonc"] = { "jq" },
      ["yaml"] = { "prettierd", "prettier" },
      ["markdown"] = { "prettierd", "prettier" },
      ["markdown.mdx"] = { "prettierd", "prettier" },
      ["graphql"] = { "prettierd", "prettier" },
      ["handlebars"] = { "prettierd", "prettier" },

      ["htmldjango"] = { "djlint" },
      ["bash"] = { "shfmt" },
      ["sh"] = { "shfmt" },

      ["sql"] = { "sql-formatter" },
      ["python"] = { "autopep8" },
      -- ["python"] = { "black" },
      ["lua"] = { "stylua" },
    },
  },
}
