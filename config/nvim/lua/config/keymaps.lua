local helper = require("utils.helper")
local notify = require("utils.notify")
local git = require("utils.git")
local utils = require("utils")
local lazygit = require("utils.lazygit").lazygit
local toggleterm = require("utils.toggleterm").toggle_float_terminal

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

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
set("n", "<leader>wn", "<C-W>n", { desc = "Split Window Right", remap = true })
-- set("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
-- set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
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
set("n", "<leader>qq", "<cmd>wqa<cr>", { desc = "Save all and quit", silent = true })

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
-- TODO: find a way to make <c-cr> work inside is_in_tmux
if utils.is_in_tmux() then
  set("i", "<C-o>", "<esc>o", { desc = "Go to next line" }) -- go to next line in insert
else
  set("i", "<C-cr>", "<esc>o", { desc = "Go to next line" }) -- go to next line in insert
end
set("i", "<C-b>", "<esc>I", { desc = "Go to beginning of line" }) -- Go to beginning of line in insert
set({ "n", "v" }, "B", "^", { desc = "Go to beginning of line" }) -- go to beginning of line in normal
set("i", "<C-e>", "<esc>A", { desc = "Go to end of line" }) -- go to end of line in insert
set({ "n", "v" }, "E", "$", { desc = "Go to end of line" }) -- go to end of line in normal
set("i", "jj", "<Esc>", { desc = "Go to normal mode" }) -- esc with jj
set("n", "<BS>", '"_ciw', { desc = "Change inner word" }) -- change word

-- NOTE: this is the way to make <c-bs> work in tmux for some reasons
if utils.is_in_tmux() then
  set({ "i", "c" }, "", "", { desc = "Delete word" }) -- delete word with <c-bs>
else
  set({ "i", "c" }, "<C-BS>", "", { desc = "Delete word" }) -- delete word with <c-bs>
end

set({ "n", "v", "x" }, "x", '"_x') -- delete text without yanking
set({ "v", "x" }, "<leader>d", '"_d', { desc = "Delete without yanking" }) -- delete selected without yanking
set({ "n" }, "<leader>d", '"_dd', { desc = "Delete without yanking" }) -- delete line without yanking
set("n", "<C-a>", "gg<S-v>G", { desc = "Select all", noremap = true, silent = true }) -- select all
--using <tab> and <s-tab> for indenting and dedenting
set("v", "<S-Tab>", "<gv", { noremap = false, silent = true })
set("v", "<Tab>", ">gv", { noremap = false, silent = true })
-- paste over currently selected text without yanking it
set({ "v", "x" }, "p", '"_dp')
set({ "v", "x" }, "P", '"_dp')
set({ "n", "v", "x" }, "c", '"_c')
set({ "n" }, "ciw", '"_ciw')

------------------------
-- Keymaps for miscellaneous
------------------------
-- stylua: ignore start
set("n", "<leader>gb", git.blame_line, { desc = "Git Blame Line" })
set("n", "<leader>fn", helper.new_file, { desc = "Create new file" })
set("n", "<leader>cx", helper.make_file_executable, { desc = "Make file executable", silent = true })
set("n", "<leader>uw", helper.toggle_line_wrap, { desc = "Toggle line wrap" })
set("n", "<leader>ud", helper.toggle_diagnostics, { desc = "Toggle Diagnostics" })
set("n", "<leader>us", helper.toggle_spell, { desc = "Toggle Spell" })
set("n", "<leader>uf", helper.toggle_autoformat, { desc = "Toggle Autoformat (Global)" })
set("n", "<leader>uS", "<cmd>Telescope spell_suggest<cr>", { desc = "Spell Suggest" })
set("n", "<leader>uF", function() helper.toggle_autoformat(true) end, { desc = "Toggle Autoformat (Buffer)" })
set("n", "<leader>uT", function()
  if vim.b.ts_highlight then
    vim.treesitter.stop()
  else
    vim.treesitter.start()
  end
end, { desc = "Toggle Treesitter Highlight" })
set("n", "<leader>uh", function()
  ---@diagnostic disable-next-line: missing-parameter
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle Inlay  hint" }) -- toggle inlay hint
set("n", "<leader>j", function() utils.duplicate_line() end, { desc = "Duplicate Line" })
set("n", "<leader><DOWN>", function() utils.duplicate_line() end, { desc = "Duplicate Line" })
set("v", "<leader>j", function() utils.duplicate_selection() end, { desc = "Duplicate selection" })
set({ "n", "i", "t" }, "<C-_>", toggleterm, { noremap = true, silent = true, desc = "Toggle Terminal" })
set("n", "<leader>gC", function()
  local git_path = vim.api.nvim_buf_get_name(0)
  lazygit({ "-f", vim.trim(git_path) }) end, { desc = "LazyGit Log" })
set("n", "<leader>gc", function() lazygit({ "log" }) end, { desc = "LazyGit Log (Current File)" })
set("n", "<leader>gg", function() lazygit() end, { desc = "LazyGit" })
set("n", "<leader>mm", function() git.lazygit() end, { desc = "LazyGit" })

-- disable arrow key in normal mode
set("n", "<UP>", function()
  notify.warn("Use k", { desc = "options" })
end)
set("n", "<DOWN>", function()
  notify.warn("Use j", { desc = "options" })
end)
set("n", "<LEFT>", function()
  notify.warn("Use h", { desc = "options" })
end)
set("n", "<RIGHT>", function()
  notify.warn("Use l", { desc = "options" })
end)
