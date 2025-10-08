local buf = Utils.ensure_buf(0)
vim.bo[buf].shiftwidth = 4
vim.bo[buf].tabstop = 4
vim.bo[buf].softtabstop = 4
vim.bo[buf].commentstring = "/*%s*/"
