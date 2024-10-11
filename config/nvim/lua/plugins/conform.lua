local lsp_utils = require("utils.lsp")

local function js_fmt(bufnr)
  local ok, clients = pcall(lsp_utils.get_clients, { name = "eslint", bufnr = bufnr })
  if ok and #clients > 0 then
    return {} -- ESLint is attached, so return nil (no additional formatter)
  end
  return { "prettierd", "prettier" } -- ESLint not found, use Prettier
end

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
      return { timeout_ms = 2500, lsp_fallback = true }
    end,
    formatters = {
      djlint = {
        command = "djlint",
        args = function()
          return {
            "--reformat",
            "-",
            "--indent",
            "2",
          }
        end,
      },
      sqlfluff = {
        args = { "format", "--dialect=ansi", "-" },
      },
    },
    formatters_by_ft = {
      ["javascript"] = js_fmt,
      ["javascriptreact"] = js_fmt,
      ["typescript"] = js_fmt,
      ["typescriptreact"] = js_fmt,
      ["vue"] = { "prettierd", "prettier" },
      ["css"] = { "prettierd", "prettier" },
      ["scss"] = { "prettierd", "prettier" },
      ["less"] = { "prettierd", "prettier" },
      ["html"] = { "prettierd", "prettier" },
      ["json"] = { "jq" },
      ["jsonc"] = { "jq" },
      ["yaml"] = { "prettierd", "prettier" },
      ["htmldjango"] = { "djlint" },
      ["bash"] = { "shfmt" },
      ["sh"] = { "shfmt" },
      ["python"] = { "autopep8" },
      -- ["python"] = { "black" },
      ["lua"] = { "stylua" },
      ["sql"] = { "sqlfluff" },
      ["mysql"] = { "sqlfluff" },
      ["plsql"] = { "sqlfluff" },
    },
  },
}
