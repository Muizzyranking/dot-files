local opt, o = vim.opt, vim.o

-- stylua: ignore start
vim.opt.clipboard                 = ""
vim.g.mapleader                   = " "
vim.g.maplocalleader              = ","
vim.g.bigfile                     = 1.5 * 1024 * 1024 -- 1.5MB
vim.g.bigfile_max_lines           = 32768
vim.g.netrw_browsex_viewer        = os.getenv("BROWSER")
vim.hl.priorities.semantic_tokens = 95
vim.g.autoformat                  = false

vim.g.maplocalleader              = ","
vim.g.mapleader                   = " "

vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)
opt.updatetime                    = 250
opt.timeoutlen                    = 300
opt.errorbells                    = false
opt.swapfile                      = false
opt.backup                        = false
opt.mouse:append("a")
opt.showmode                      = false
opt.signcolumn                    = "yes"
opt.scrolloff                     = 4
opt.sidescrolloff                 = 8
opt.confirm                       = true
opt.showmode                      = false
opt.statuscolumn                  = [[%!v:lua.require'snacks.statuscolumn'.get()]]
opt.background                    = "dark"
opt.winminwidth                   = 5
opt.signcolumn                    = "yes"
opt.termguicolors                 = true
opt.inccommand                    = "nosplit"
o.equalalways                     = true
opt.fillchars                     = {
  foldopen                        = "",
  foldclose                       = "",
  fold                            = " ",
  foldsep                         = " ",
  diff                            = "╱",
  eob                             = " ",
}
opt.wrap                          = false
opt.smoothscroll                  = true
opt.foldtext                      = ""
opt.foldlevel                     = 99
opt.foldmethod                    = "indent"
opt.undofile                      = true
opt.ignorecase                    = true
opt.smartcase                     = true
opt.hlsearch                      = true
opt.number                        = true
opt.relativenumber                = true
opt.cursorline                    = true
opt.tabstop                       = 4
opt.shiftwidth                    = 4
opt.expandtab                     = true
opt.autoindent                    = true
opt.smartindent                   = true
opt.completeopt                   = { "menuone", "noinsert", "noselect" }
opt.backspace                     = { "eol", "indent", "start" }
opt.iskeyword:append("-")
opt.splitright                    = true
opt.splitbelow                    = true
opt.splitkeep                     = "screen"
opt.sessionoptions                = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" } -- Set session options
opt.spelllang                     = { "en" }
opt.spell                         = false
opt.pumblend                      = 0
opt.winblend                      = 0
opt.pumheight                     = 10
-- opt.indentexpr                 = "v:lua.Utils.treesitter.indentexpr() -- treesitter indents
opt.indentexpr                    = "v:lua.require('utils.treesitter').indentexpr()"
-- opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
--stylua: ignore end
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    vim.cmd("setlocal formatoptions-=c formatoptions-=o")
  end,
})

local providers = { "ruby", "node", "perl" }
for _, provider in ipairs(providers) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end
