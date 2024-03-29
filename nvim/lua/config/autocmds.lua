-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "json", "jsonc", "markdown" },
    callback = function()
        vim.wo.conceallevel = 0
    end,
})

--do not expand tabs in C file
-- vim.api.nvim_exec(
--   [[
--   augroup CFileSettings
--     autocmd!
--     autocmd FileType c, h setlocal noexpandtab | setlocal tabstop=8 | setlocal shiftwidth=8 | setlocal autoindent | setlocal smartindent
--   augroup END
-- ]],
--   false
-- )

vim.api.nvim_exec(
    [[
  augroup CFileSettings
    autocmd!
    autocmd BufRead,BufNewFile *.c,*.h setlocal noexpandtab | setlocal tabstop=8 | setlocal shiftwidth=8 | setlocal autoindent | setlocal smartindent
  augroup END
]],
    false
)

-- don't auto comment new line
vim.api.nvim_create_autocmd("BufEnter", { command = [[set formatoptions-=cro]] })
