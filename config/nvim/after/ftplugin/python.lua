local utils = require("utils")

-- vim.bo.shiftwidth = 4
-- vim.bo.tabstop = 4
vim.b.disable_autoformat = false
vim.g.disable_autoformat = false

vim.g.disable_autoformat = false -- enable autoformat on save in python
if utils.has("venv-selector.nvim") then
  vim.api.nvim_buf_set_keymap(0, "n", "<leader>cv", "<cmd>VenvSelect<cr>", { desc = "Select VirtualEnv" })
end
