return {
  keys = {
    {
      "<leader>ci",
      function()
        vim.lsp.buf.code_action({
          filter = function(a)
            return a.title:match("Add import from") or a.kind == "quickfix"
          end,
          apply = true,
        })
      end,
      desc = "Add missing imports",
    },
  },
}
