local func = require("config.functions")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.showmode = false
local set = vim.keymap.set

------------------------
-- Keymaps for moving chunks of text/code
------------------------
set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

------------------------
-- Keymaps for navigation
------------------------
set({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
set({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
set({ "n", "t" }, "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
set({ "n", "t" }, "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
set({ "n", "t" }, "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
set({ "n", "t" }, "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

------------------------
-- Keymaps for window management
------------------------
set("n", "<leader>ww", "<C-W>p", { desc = "Other Window", remap = true })
set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
set("n", "<leader>w-", "<C-W>s", { desc = "Split Window Below", remap = true })
set("n", "<leader>w|", "<C-W>v", { desc = "Split Window Right", remap = true })
set("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })

------------------------
-- Keymaps for saving and quitting
------------------------
set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
set("n", "<C-q>", "<cmd>q<cr>", { desc = "Quit file", silent = true })
set("n", "<C-Q>", "<cmd>q!<cr>", { desc = "Quit file", silent = true })
set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit file", silent = true })

------------------------
-- Keymaps for search
------------------------
set("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
set("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
set("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
set("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
set("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
set("n", "<Esc>", "<cmd>nohlsearch<CR>") -- Clear search highlight on pressing <Esc> in normal mode

------------------------
-- Keymaps for editing
------------------------
set("i", "<C-o>", "<esc>o", { desc = "Go to next line" })
-- set("i", "<C-b>", "<esc>I", { desc = "Go to begginin of line" })
-- WARN: C-b not working
set("i", "<C-b>", "<esc>I", { desc = "Go to beginning of line", noremap = true, silent = true }) -- Go to beginning of line
set("n", "B", "^", { desc = "Go to beginning of line" })
set("i", "<C-e>", "<esc>A", { desc = "Go to end of line" })
set("n", "E", "$", { desc = "Go to end of line" })
set("i", "jj", "<Esc>", { desc = "Go to normal mode" })
set("n", "<BS>", '"_ciw', { desc = "Change inner word" })

------------------------
-- Keymaps for terminal
------------------------
set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

------------------------
-- Keymaps for miscellaneous
------------------------
set("n", "<leader>gg", ":LazyGit<cr>", { desc = "Open LazyGit", silent = true })
set("n", "<leader>cx", "<cmd>!chmod +x %<cr>", { desc = "Make file executable", silent = true })

set("n", "<leader>uw", func.toggle_line_wrap, { desc = "Toggle line wrap" })
set("n", "<leader>ud", func.toggle_diagnostics, { desc = "Toggle Diagnostics" })
set("n", "<leader>us", func.toggle_spell, { desc = "Toggle Spell" })
set("n", "<leader>uf", func.toggle_autoformat, { desc = "Toggle Autoformat (Global)" })
-- set("n", "<leader>uF", func.toggle_autoformat_buffer, { desc = "Toggle Autoformat (Buffer)" })

set("n", "x", '"_x')

-- buffers
set("n", "<leader>bd", "<cmd>bd<cr>", { desc = "Delete buffer", silent = true })
set("n", "<S-h>", "<cmd>bnext<cr>", { desc = "Prev buffer", silent = true })
set("n", "<S-l>", "<cmd>bNext<cr>", { desc = "Next buffer", silent = true })

-- paste over currently selected text without yanking it
set({ "v", "x" }, "p", '"_dP')
set({ "v", "x" }, "P", '"_dp')
set({ "n", "v", "x" }, "c", '"_c')
set({ "n" }, "ciw", '"_ciw')

-- Select all
set("n", "<C-a>", "gg<S-v>G", { desc = "Select all", noremap = true, silent = true })

-- better indenting
--using <tab> and <s-tab> for indenting and dedenting
set("v", "<S-Tab>", "<gv", { noremap = false, silent = true })
set("v", "<Tab>", ">gv", { noremap = false, silent = true })

--esc with jj
set("i", "jj", "<Esc>", { desc = "Go to normal mode" })
