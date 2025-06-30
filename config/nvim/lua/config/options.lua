local o = vim.opt

-- stylua: ignore start
-----------------------------------------------------------
-- General
-----------------------------------------------------------
-- o.wildignore:append({ "*/colors/*.vim", "*/colors/vim.lua" })
o.clipboard                    = "unnamedplus" -- use system clipboard
o.updatetime                   = 250 -- Decrease update time
o.timeoutlen                   = 300
o.errorbells                   = false -- Disable error bells
o.swapfile                     = false -- Disable swap files
o.backup                       = false -- Disable backup files
o.mouse:append("a") -- Enable mouse support
o.showmode                     = false -- Don't show the mode, since it's already in the status line
o.signcolumn                   = "yes" -- Keep signcolumn on by default
o.scrolloff                    = 4 -- Minimal number of screen lines to keep above and below the cursor
o.sidescrolloff                = 8
o.confirm                      = true -- Confirm before quitting unsaved buffers

-----------------------------------------------------------
-- UI
-----------------------------------------------------------
o.showmode                     = false
o.statuscolumn                 = [[%!v:lua.require'snacks.statuscolumn'.get()]]
o.background                   = "dark"
o.winminwidth                  = 5 -- Minimum window width
o.signcolumn                   = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
o.termguicolors                = true -- Enable true color support
o.inccommand                   = "nosplit" -- Don't Preview substitutions live, as you type!
-- Customize fold characters
o.fillchars                    = {
  foldopen                     = "",
  foldclose                    = "",
  fold                         = " ",
  foldsep                      = " ",
  diff                         = "╱",
  eob                          = " ",
}
o.wrap                         = false -- Disable line wrapping
o.smoothscroll                 = true -- Smooth scrolling

if vim.g.neovide then
  vim.g.neovide_transparency   = 1
  vim.g.transparency           = 0.8
  vim.g.neovide_window_blurred = true
  vim.o.guifont                = "Maple Mono NF:h11"
end
-----------------------------------------------------------
-- Undo and Backup
-----------------------------------------------------------
-- Save undo history
o.undofile                     = true
-- opt.undodir                 = vim.fn.expand("~/.nvim/undodir")

-----------------------------------------------------------
-- Search and Highlighting
-----------------------------------------------------------
-- Case-insensitive searching UNLESS \C or capital in search
o.ignorecase                   = true
o.smartcase                    = true
o.hlsearch                     = true -- Highlight search results

-----------------------------------------------------------
-- Line Numbers and Cursor
-----------------------------------------------------------
o.number                       = true -- Show line numbers
o.relativenumber               = true -- Highlight the current line
o.cursorline                   = true

-----------------------------------------------------------
-- Indentation
-----------------------------------------------------------
o.tabstop                      = 4 -- 4 spaces for tabs
o.shiftwidth                   = 4 -- 4 spaces for indent width
o.expandtab                    = true -- Expand tabs to spaces
o.autoindent                   = true -- Copy indent from current line when starting new one
o.smartindent                  = true -- Enable smart indentation

-----------------------------------------------------------
-- Completion
-----------------------------------------------------------
o.completeopt                  = { "menuone", "noinsert", "noselect" }

-----------------------------------------------------------
-- Miscellaneous
-----------------------------------------------------------
o.backspace                    = { "eol", "indent", "start" } -- Allow backspace in insert mode
o.iskeyword:append("-") -- Treat dash as a word character
o.splitright                   = true -- Configure how new splits should be opened
o.splitbelow                   = true -- Configure how new splits should be opened
o.splitkeep                    = 'screen'
o.sessionoptions               = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" } -- Set session options
o.spelllang                    = { "en" } -- Set spell languages
o.spell                        = false -- Disable spell checking by default

o.pumblend                     = 0 -- Popup blend
o.winblend                     = 0 -- Popup blend
o.pumheight                    = 10 -- Maximum number of entries in a popup
-- opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
-- stylua: ignore end

local providers = { "ruby", "node", "perl", "python" }
for _, provider in ipairs(providers) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

if Utils.is_executable("python3") then
  vim.g.python3_host_prog = vim.fn.exepath("python3")
end
