local utils = require("utils")
vim.bo.shiftwidth = 8
vim.bo.tabstop = 8
vim.bo.softtabstop = 8
vim.bo.expandtab = false

vim.g.disable_autoformat = false
vim.b.disable_autoformat = false

if utils.has("clangd_extensions.nvim") then
  vim.api.nvim_buf_set_keymap(
    0,
    "n",
    "<leader>ch",
    "<cmd>ClangdSwitchSourceHeader<cr>",
    { desc = "Switch Source/Header" }
  )
end
