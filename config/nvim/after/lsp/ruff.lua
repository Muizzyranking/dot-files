return {
  on_attach = function(client, _)
    client.server_capabilities.hoverProvider = false
  end,
  keys = {
    {
      "<leader>co",
      Utils.lsp.action["source.organizeImports"],
      desc = "Organize Imports",
      icon = { icon = "󰺲" },
    },
    {
      "<leader>cu",
      function()
        local diag = vim.diagnostic.get(Utils.ensure_buf(0))
        local ruff_diags = vim.tbl_filter(function(d)
          return d.source and Utils.evaluate(d.source:lower(), "ruff")
        end, diag)
        if #ruff_diags > 0 then Utils.lsp.action["source.fixAll.ruff"]() end
      end,
      desc = "Fix all fixable diagnostics",
      icon = { icon = "󰁨 ", color = "red" },
    },
    {
      "<leader>cU",
      function()
        require("conform").format({
          buf = Utils.ensure_buf(0),
          formatters = { "ruff_fix" },
          timeout_ms = 3000,
        })
      end,
      desc = "Fix all",
      icon = { icon = "󰁨 ", color = "red" },
    },
  },
}
