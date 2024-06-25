local opt = vim.opt

vim.highlight.priorities.semantic_tokens = 95

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
opt.scrolloff = 4 -- Minimal number of screen lines to keep above and below the cursor
opt.sidescrolloff = 8
opt.confirm = true -- Confirm before quitting unsaved buffers
-----------------------------------------------------------
-- UI
-----------------------------------------------------------
opt.showmode = false
opt.statuscolumn = [[%!v:lua.require("utils.ui").statuscolumn()]]
vim.o.background = "dark"
opt.winminwidth = 5 -- Minimum window width
opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
-- vim.opt.numberwidth = 1
opt.termguicolors = true -- Enable true color support
opt.inccommand = "nosplit" -- Don't Preview substitutions live, as you type!
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
-- smooth scrolling available in neovim >= 0.10.0
if vim.fn.has("nvim-0.10") == 1 then
  opt.smoothscroll = true -- Smooth scrolling
end

-----------------------------------------------------------
-- Undo and Backup
-----------------------------------------------------------
-- Save undo history
opt.undofile = true
-- opt.undodir = vim.fn.expand("~/.nvim/undodir")

-----------------------------------------------------------
-- Folding
-----------------------------------------------------------
opt.foldlevel = 99
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
vim.g.markdown_folding = 1 -- Enable markdown folding

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
opt.splitright = true -- Configure how new splits should be opened
opt.splitbelow = true -- Configure how new splits should be opened
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" } -- Set session options
opt.spelllang = { "en" } -- Set spell languages
opt.spell = false -- Disable spell checking by default
-- vim.g.autoformat = false -- Disable autoformat by default
vim.g.disable_autoformat = true
vim.b.disable_autoformat = true
vim.g.loaded_ruby_provider = 0 -- Disable Ruby providers
vim.g.loaded_perl_provider = 0 -- Disable Perl providers

opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
-- opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions

-- Diagnostic signs
local icons = require("utils.icons").diagnostics
vim.fn.sign_define("DiagnosticSignError", { text = icons.Error, texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = icons.Warn, texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInfo", { text = icons.Info, texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = icons.Hint, texthl = "DiagnosticSignHint" })
