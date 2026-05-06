---@type LspExtras
return {
  enabled = true,
  keys = {
    {
      "<leader>ci",
      function()
        vim.lsp.buf.code_action({
          filter = function(a)
            return a.title:find("import") ~= nil and a.kind == "quickfix"
          end,
          apply = true,
        })
      end,
      desc = "Auto import word under cursor",
      icon = { icon = "󰋺 ", color = "blue" },
    },
  },
}
