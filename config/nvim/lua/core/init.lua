vim.g.mapleader = " "
vim.g.maplocalleader = ","

if vim.env.VSCODE then
	vim.g.vscode = true
end

local sep = vim.fn.has("win32") == 1 and ";" or ":"
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if not vim.env.PATH:find(mason_bin, 1, true) then
	vim.env.PATH = mason_bin .. sep .. vim.env.PATH
end

_G.Utils = require("utils")
_G.Pack = require("core.pack")
_G.P = function(...)
	vim.print(vim.inspect(...))
end

Pack.now(function()
	require("lsp")
	vim.cmd.colorscheme("custom")
end)

Pack.defer(function()
	Utils.map.setup()
	Utils.root.setup()
	Utils.format.setup()
	require("statusline").setup()
end)

Pack.lazy_file(function()
	require("breadcrumb").setup()
end)
