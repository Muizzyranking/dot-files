Utils.lsp.register_keys("ruff", {
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
})
return {}
