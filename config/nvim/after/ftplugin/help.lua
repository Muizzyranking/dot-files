vim.opt.spell = false
local set = vim.keymap.set
local opts = { noremap = true, buffer = true, desc = "go to definition" }
set("n", "gd", "<c-]>", opts)
set("n", "<cr>", "<c-]>", opts)
