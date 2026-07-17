vim.g.mapleader = " "
vim.g.maplocalleader = ","

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
