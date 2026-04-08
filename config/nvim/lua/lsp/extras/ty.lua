return {
  enabled = false,
  keys = {
    {
      "<leader>ci",
      function()
        vim.lsp.buf.code_action({
          filter = function(a)
            return a.title:match("^import ") and a.kind == "quickfix" and a.isPreferred == true
          end,
          apply = true,
        })
      end,
      desc = "Auto import word under cursor",
      icon = { icon = "󰋺 ", color = "blue" },
    },
  },
}
