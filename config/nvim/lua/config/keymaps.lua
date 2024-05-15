local func = require("config.functions")
local utils = require("config.utils")
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- vim.keymap.del("n")

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
set({ "n" }, "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
set({ "n" }, "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
set({ "n" }, "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
set({ "n" }, "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })
set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
set("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
set("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
set("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
set("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })

------------------------
-- Keymaps for window management
------------------------
set("n", "<leader>ww", "<C-W>p", { desc = "Other Window", remap = true })
set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
set("n", "<leader>w-", "<C-W>s", { desc = "Split Window Below", remap = true })
set("n", "<leader>w|", "<C-W>v", { desc = "Split Window Right", remap = true })
set("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
-- Resize window using <ctrl> arrow keys
set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

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
-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
set("n", "N", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
set("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
set("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
set("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
set("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
set("n", "<Esc>", "<cmd>nohlsearch<CR>") -- Clear search highlight on pressing <Esc> in normal mode

------------------------
-- Keymaps for editing
------------------------
set("i", "<C-o>", "<esc>o", { desc = "Go to next line" }) -- go to next line in insert
set("i", "<C-b>", "<esc>I", { desc = "Go to beginning of line" }) -- Go to beginning of line in insert
set({ "n", "v" }, "B", "^", { desc = "Go to beginning of line" }) -- go to beginning of line in normal
set("i", "<C-e>", "<esc>A", { desc = "Go to end of line" }) -- go to end of line in insert
set({ "n", "v" }, "E", "$", { desc = "Go to end of line" }) -- go to end of line in normal
set("i", "jj", "<Esc>", { desc = "Go to normal mode" }) -- esc with jj
set("n", "<BS>", '"_ciw', { desc = "Change inner word" }) -- change word
set("n", "x", '"_x') -- delete text without yanking
set({ "v", "x" }, "<leader>d", '"_d', { desc = "Delete without yanking" }) -- delete selected without yanking
set({ "n" }, "<leader>d", '"_dd', { desc = "Delete without yanking" }) -- delete line without yanking
set("n", "<C-a>", "gg<S-v>G", { desc = "Select all", noremap = true, silent = true }) -- select all
--using <tab> and <s-tab> for indenting and dedenting
set("v", "<S-Tab>", "<gv", { noremap = false, silent = true })
set("v", "<Tab>", ">gv", { noremap = false, silent = true })
-- paste over currently selected text without yanking it
set({ "v", "x" }, "p", '"_dP')
set({ "v", "x" }, "P", '"_dp')
set({ "n", "v", "x" }, "c", '"_c')
set({ "n" }, "ciw", '"_ciw')

------------------------
-- Keymaps for miscellaneous
------------------------
-- set("n", "<leader>cx", "<cmd>!chmod +x %<cr>", { desc = "Make file executable", silent = true })
set("n", "<leader>cx", func.make_file_executable, { desc = "Make file executable", silent = true })
set("n", "<leader>uw", func.toggle_line_wrap, { desc = "Toggle line wrap" })
set("n", "<leader>ud", func.toggle_diagnostics, { desc = "Toggle Diagnostics" })
set("n", "<leader>us", func.toggle_spell, { desc = "Toggle Spell" })
set("n", "<leader>uf", func.toggle_autoformat, { desc = "Toggle Autoformat (Global)" })
-- set("n", "<leader>uF", func.toggle_autoformat_buffer, { desc = "Toggle Autoformat (Buffer)" })

-- buffers
-- if not utils.has("bufferline.nvim") then
set("n", "<S-h>", "<cmd>bp<cr>", { desc = "Prev buffer", silent = true })
set("n", "<S-l>", "<cmd>bn<cr>", { desc = "Next buffer", silent = true })
set("n", "<leader>bd", "<cmd>bd<cr>", { desc = "Delete buffer", silent = true })
-- end
