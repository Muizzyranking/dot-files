-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
local create_autocmd = vim.api.nvim_create_autocmd

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc", "markdown" },
  callback = function()
    vim.wo.conceallevel = 0
  end,
})

-- use tab in c files

vim.api.nvim_create_augroup("CFileSettings", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = "CFileSettings",
  pattern = { "*.c", "*.h" },
  command = "setlocal noexpandtab | setlocal tabstop=8 | setlocal shiftwidth=8 | setlocal autoindent | setlocal smartindent",
})

vim.api.nvim_create_augroup("WebLangSettings", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = "WebLangSettings",
  pattern = { "*.js", "*.html", "*.json", "*.css" },
  command = "setlocal tabstop=2 | setlocal shiftwidth=2 | setlocal autoindent | setlocal smartindent",
})

-- don't auto comment new line
-- vim.api.nvim_create_autocmd("BufEnter", { command = [[set formatoptions-=cro]] })
