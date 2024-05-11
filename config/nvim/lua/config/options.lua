local opt = vim.opt

-----------------------------------------------------------
-- General
-----------------------------------------------------------
opt.clipboard = "unnamedplus" -- Use system clipboard
opt.updatetime = 250 -- Decrease update time
opt.timeoutlen = 300
opt.errorbells = false -- Disable error bells
opt.swapfile = false -- Disable swap files
opt.backup = false -- Disable backup files
opt.mouse:append("a") -- Enable mouse support
opt.showmode = false -- Don't show the mode, since it's already in the status line
opt.signcolumn = "yes" -- Keep signcolumn on by default
opt.scrolloff = 10 -- Minimal number of screen lines to keep above and below the cursor
opt.confirm = true -- Confirm before quitting unsaved buffers

-----------------------------------------------------------
-- UI
-----------------------------------------------------------
opt.termguicolors = true -- Enable true color support
-- Customize fold characters
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.wrap = false -- Disable line wrapping

-----------------------------------------------------------
-- Undo and Backup
-----------------------------------------------------------
-- Save undo history
opt.undofile = true
-- opt.undodir = vim.fn.expand("~/.nvim/undodir")

-----------------------------------------------------------
-- Folding
-----------------------------------------------------------
opt.foldmethod = "indent" -- Set folding method
opt.foldenable = true -- Disable folding by default
opt.foldlevel = 99 -- Set maximum fold level
vim.g.markdown_folding = 1 -- Enable markdown folding
vim.o.foldcolumn = "0" -- Set foldcolumn width
vim.o.foldlevelstart = 100 -- Set initial folding level

-----------------------------------------------------------
-- Search and Highlighting
-----------------------------------------------------------
-- Case-insensitive searching UNLESS \C or capital in search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true -- Highlight search results

-----------------------------------------------------------
-- Line Numbers and Cursor
-----------------------------------------------------------
opt.number = true -- Show line numbers
opt.relativenumber = true -- Highlight the current line
opt.cursorline = true

-----------------------------------------------------------
-- Indentation
-----------------------------------------------------------
opt.tabstop = 4 -- 4 spaces for tabs
opt.shiftwidth = 4 -- 4 spaces for indent width
opt.expandtab = true -- Expand tabs to spaces
opt.autoindent = true -- Copy indent from current line when starting new one
opt.smartindent = true -- Enable smart indentation

-----------------------------------------------------------
-- Completion
-----------------------------------------------------------
opt.completeopt = { "menuone", "noinsert", "noselect" }

-----------------------------------------------------------
-- Miscellaneous
-----------------------------------------------------------
opt.backspace = { "eol", "indent", "start" } -- Allow backspace in insert mode
opt.iskeyword:append("-") -- Treat dash as a word character
opt.inccommand = "split" -- Preview substitutions live, as you type!
opt.splitright = true -- Configure how new splits should be opened
opt.splitbelow = true -- Configure how new splits should be opened
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" } -- Set session options
opt.spelllang = { "en" } -- Set spell languages
vim.g.autoformat = false -- Disable autoformat by default
vim.g.loaded_ruby_provider = 0 -- Disable Ruby providers
vim.g.loaded_perl_provider = 0 -- Disable Perl providers
