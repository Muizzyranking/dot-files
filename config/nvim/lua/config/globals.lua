-- stylua: ignore start
vim.g.mapleader                          = " "
vim.g.maplocalleader                     = "\\"
vim.g.big_file                           = 1.5 * 1024 * 1024 -- 1.5MB
vim.g.max_lines                          = 500
vim.g.netrw_browsex_viewer               = os.getenv("BROWSER")
vim.highlight.priorities.semantic_tokens = 95
vim.g.autoformat                         = false
