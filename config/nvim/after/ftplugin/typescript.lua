local map = vim.keymap.set

map("n", "<leader>cR", function()
  vim.lsp.buf.code_action({
    apply = true,
    context = {
      only = { "source.removeUnused.ts" },
      diagnostics = {},
    },
  })
end, { noremap = true, silent = true, "Remove Unused Imports" })

map("n", "<leader>co", function()
  vim.lsp.buf.code_action({
    apply = true,
    context = { only = { "source.organizeImports.ts" }, diagnostics = {} },
  })
end, { noremap = true, silent = true, desc = "Organize Imports" })
