return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo" },
  keys = {},
  init = function()
    Utils.on_very_lazy(function()
      Utils.format.register({
        name = "conform.nvim",
        priority = 100,
        primary = true,
        format = function(buf)
          require("conform").format({ bufnr = buf })
        end,
        sources = function(buf)
          local ret = require("conform").list_formatters(buf)
          ---@param v conform.FormatterInfo
          return vim.tbl_map(function(v)
            return v.name
          end, ret)
        end,
      })
    end)
  end,
  opts = {
    notify_on_error = true,
    formatters = {},
    formatters_by_ft = {
      ["yaml"] = { "prettierd", "prettier" },
      ["lua"] = { "stylua" },
    },
  },
}
