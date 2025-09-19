local opt, o = vim.opt, vim.o

-- stylua: ignore start
-----------------------------------------------------------
-- General
-----------------------------------------------------------
-- o.wildignore:append({ "*/colors/*.vim", "*/colors/vim.lua" })
opt.clipboard      = "unnamedplus" -- use system clipboard
opt.updatetime     = 250 -- Decrease update time
opt.timeoutlen     = 300
opt.errorbells     = false -- Disable error bells
opt.swapfile       = false -- Disable swap files
opt.backup         = false -- Disable backup files
opt.mouse:append("a") -- Enable mouse support
opt.showmode       = false -- Don't show the mode, since it's already in the status line
opt.signcolumn     = "yes" -- Keep signcolumn on by default
opt.scrolloff      = 4 -- Minimal number of screen lines to keep above and below the cursor
opt.sidescrolloff  = 8
opt.confirm        = true -- Confirm before quitting unsaved buffers

-----------------------------------------------------------
-- UI
-----------------------------------------------------------
opt.showmode       = false
opt.statuscolumn   = [[%!v:lua.require'snacks.statuscolumn'.get()]]
opt.background     = "dark"
opt.winminwidth    = 5 -- Minimum window width
opt.signcolumn     = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opt.termguicolors  = true -- Enable true color support
opt.inccommand     = "nosplit" -- Don't Preview substitutions live, as you type!
o.equalalways      = true
-- Customize fold characters
opt.fillchars      = {
  foldopen         = "",
  foldclose        = "",
  fold             = " ",
  foldsep          = " ",
  diff             = "╱",
  eob              = " ",
}
opt.wrap           = false -- Disable line wrapping
opt.smoothscroll   = true -- Smooth scrolling

-----------------------------------------------------------
-- Undo and Backup
-----------------------------------------------------------
-- Save undo history
opt.undofile       = true
-- opt.undodir     = vim.fn.expand("~/.nvim/undodir")

-----------------------------------------------------------
-- Search and Highlighting
-----------------------------------------------------------
-- Case-insensitive searching UNLESS \C or capital in search
opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = true -- Highlight search results

-----------------------------------------------------------
-- Line Numbers and Cursor
-----------------------------------------------------------
opt.number         = true -- Show line numbers
opt.relativenumber = true -- Highlight the current line
opt.cursorline     = true

-----------------------------------------------------------
-- Indentation
-----------------------------------------------------------
opt.tabstop        = 4 -- 4 spaces for tabs
opt.shiftwidth     = 4 -- 4 spaces for indent width
opt.expandtab      = true -- Expand tabs to spaces
opt.autoindent     = true -- Copy indent from current line when starting new one
opt.smartindent    = true -- Enable smart indentation

-----------------------------------------------------------
-- Completion
-----------------------------------------------------------
opt.completeopt    = { "menuone", "noinsert", "noselect" }

-----------------------------------------------------------
-- Miscellaneous
-----------------------------------------------------------
opt.backspace      = { "eol", "indent", "start" } -- Allow backspace in insert mode
opt.iskeyword:append("-") -- Treat dash as a word character
opt.splitright     = true -- Configure how new splits should be opened
opt.splitbelow     = true -- Configure how new splits should be opened
opt.splitkeep      = 'screen'
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" } -- Set session options
opt.spelllang      = { "en" } -- Set spell languages
opt.spell          = false -- Disable spell checking by default

opt.pumblend       = 0 -- Popup blend
opt.winblend       = 0 -- Popup blend
opt.pumheight      = 10 -- Maximum number of entries in a popup
opt.indentexpr     = "v:lua.Utils.treesitter.indentexpr()" -- treesitter indents
-- opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
-- stylua: ignore end

local providers = { "ruby", "node", "perl", "python" }
for _, provider in ipairs(providers) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

if Utils.is_executable("python3") then vim.g.python3_host_prog = vim.fn.exepath("python3") end
