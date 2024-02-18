-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps her
local del = vim.keymap.del
local set = vim.keymap.set
-- local opts = { noremap = true, silent = true }

del("n", "<c-/>")

-- set("n", "x", '"_x')

-- Select all
set("n", "<C-a>", "gg<S-v>G", { desc = "Select all" })

--toggleterm
set("n", "<C-\\>", "<cmd>ToggleTerm<CR>", { desc = "Open Terminal" })

--use ctrl-q to quit
set("n", "<C-Q>", "<cmd>qa<cr>", { desc = "Quit all" })
set("n", "<C-q>", "<cmd>q<cr>", { desc = "Quit" })

-- set jj as esc key
set("i", "jj", "<esc>", { desc = "Esc" })

-- go to the end of a line
set("n", "E", "$", { noremap = false })
set("v", "E", "$", { noremap = false })
set("i", "<C-e>", "<esc>A", { noremap = false })

-- go to beginning of the line
set("n", "B", "^", { noremap = false })
set("v", "B", "^", { noremap = false })
set("i", "<C-b>", "<esc>I", { noremap = false })

--go to next line in insert mode
set("i", "<C-o>", "<esc>o", { noremap = false })

--use ; to go to command mode
set("n", ";", ":")

--dont copy when pasting
set("n", "p", '"_dP')
set("v", "p", '"_dP')

--comment with <leader>/
set("n", "<leader>/", "gcc", { remap = true, silent = true })
set("v", "<leader>/", "gc", { remap = true, silent = true })
set("x", "<leader>/", "gc", { remap = true, silent = true })
