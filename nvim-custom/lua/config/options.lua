vim.g.mapleader = " "
local opt = vim.opt

--line  number
opt.number = true
opt.relativenumber = true

--indentation
opt.tabstop = 4 -- 4 spaces for tabs (prettier default)
opt.shiftwidth = 4 -- 4 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one
opt.smartindent = true
opt.cursorline = true
opt.clipboard = "unnamedplus"

opt.termguicolors = true

opt.fillchars = {
  foldopen = "",
  foldclose = "",
  -- fold = "⸱",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

opt.completeopt = {"menuone", "noinsert", "noselect"}

opt.errorbells = false
opt.swapfile = false
opt.backup = false
--opt.undodir = vim.fn.expand("~/.nvim/undodir")
--opt.undofile = true
opt.backspace = {"eol", "indent", "start"}
opt.splitright = true
opt.splitbelow = true
opt.iskeyword:append("-")
opt.mouse:append("a")


