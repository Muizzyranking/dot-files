-- stylua: ignore start
vim.hl = vim.highlight or vim.hl
vim.g.mapleader                          = " "
vim.g.maplocalleader                     = "\\"
vim.g.bigfile                            = 1.5 * 1024 * 1024 -- 1.5MB
vim.g.bigfile_max_lines                  = 32768
vim.g.netrw_browsex_viewer               = os.getenv("BROWSER")
vim.hl.priorities.semantic_tokens = 95
vim.g.autoformat                         = false
vim.g.clipboard = {
  name = 'WL-Clipboard',
  copy = {
    ['+'] = 'wl-copy --type text/plain',
    ['*'] = 'wl-copy --primary --type text/plain',
  },
  paste = {
    ['+'] = 'wl-paste --no-newline',
    ['*'] = 'wl-paste --primary --no-newline',
  },
  cache_enabled = 1,
}
