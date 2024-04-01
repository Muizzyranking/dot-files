local opt = vim.opt

--vim.g.have_nerd_font = false
-- Save undo history
vim.opt.undofile = true
-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

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

opt.completeopt = { "menuone", "noinsert", "noselect" }

opt.errorbells = false
opt.swapfile = false
opt.backup = false
--opt.undodir = vim.fn.expand("~/.nvim/undodir")
--opt.undofile = true
opt.backspace = { "eol", "indent", "start" }
opt.iskeyword:append("-")
opt.mouse:append("a")

-- Don't show the mode, since it's already in status line
vim.opt.showmode = false

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10
