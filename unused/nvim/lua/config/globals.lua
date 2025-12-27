-- stylua: ignore start
vim.hl                            = vim.hl or vim.highlight
vim.opt.clipboard                 = ""
vim.g.mapleader                   = " "
vim.g.maplocalleader              = ","
vim.g.bigfile                     = 1.5 * 1024 * 1024 -- 1.5MB
vim.g.bigfile_max_lines           = 32768
vim.g.netrw_browsex_viewer        = os.getenv("BROWSER")
vim.hl.priorities.semantic_tokens = 95
vim.g.autoformat                  = false
