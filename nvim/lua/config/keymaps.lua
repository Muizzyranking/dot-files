-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps her
local set = vim.keymap.set
-- local opts = { noremap = true, silent = true }
-- local maps = require("lazyvim.util")
set("n", "x", '"_x')

-- Select all
set("n", "<C-a>", "gg<S-v>G")

--toggleterm
set("n", "<C-\\>", "<cmd>ToggleTerm<CR>", { desc = "Open Terminal" })
--
set("n", "<C-Q>", "<cmd>qa<cr>", { desc = "Quit all" })
set("n", "<C-q>", "<cmd>q<cr>", { desc = "Quit" })

-- set jj as esc key
set("i", "jj", "<esc>", { desc = "Esc" })
set("v", "jj", "<esc>", { desc = "Esc" })

set("n", "E", "$", { noremap = false })
set("n", "B", "^", { noremap = false })
