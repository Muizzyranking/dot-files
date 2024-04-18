-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt
-- opt.expandtab = false
opt.tabstop = 4
opt.shiftwidth = 4

opt.iskeyword:append({ "-" })
opt.swapfile = false
opt.backup = false

-- disable auto format
vim.g.autoformat = false
