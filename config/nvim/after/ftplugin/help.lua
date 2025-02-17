vim.opt.spell = false
local buf = vim.api.nvim_get_current_buf()
vim.keymap.set("n", "gd", "<c-]>", { remap = true, buffer = buf, desc = "go to definition" })
