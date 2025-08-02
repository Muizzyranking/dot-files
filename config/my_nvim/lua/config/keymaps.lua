vim.g.mapleader = " "
local set = vim.keymap.set
vim.keymap.set("n", "<leader>e", "<cmd>Lex 30<cr>")
set({ "n", "i", "v" }, "<c-s>", "<cmd>w<cr><esc>", { silent = true, desc = "Save file" })
set("n", "<c-q>", "<cmd>q<cr>", { silent = true, desc = "Quit" })
