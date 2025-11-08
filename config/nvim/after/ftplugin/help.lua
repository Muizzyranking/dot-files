vim.opt_local.spell = false
local set = vim.keymap.set
local opts = { noremap = true, buffer = Utils.ensure_buf(0), desc = "go to definition" }
set("n", "<cr>", "<c-]>", opts)
