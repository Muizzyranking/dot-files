-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps her
local Util = require("lazyvim.util")
local map = Util.safe_keymap_set
-- quit
map("n", "<C-q>", "<cmd>qa<cr>", { desc = "Quit all" })

-- floating terminal
local lazyterm = function()
  Util.terminal(nil, { cwd = Util.root() })
end
map("n", "<leader>ft", lazyterm, { desc = "Terminal (root dir)" })
map("n", "<c-\\>", function()
  Util.terminal()
end, { desc = "Terminal (cwd)" })
map("n", "<c-/>", lazyterm, { desc = "Terminal (cwd)" })
map("n", "<c-_>", lazyterm, { desc = "which_key_ignore" })

map("t", "<C-\\>", "<cmd>close<cr>", { desc = "Hide Terminal" })
--Neotree
-- map("n", "<leader>e", "<cmd>Neotree<cr>", { desc = "Neotree CWD" })
