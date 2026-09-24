vim.g.mapleader = " "
vim.g.maplocalleader = ","

if vim.env.VSCODE then
	vim.g.vscode = true
end

_G.Settings = require("config.settings")
_G.Utils = require("utils")
_G.Pack = require("core.pack")
_G.P = function(...)
	vim.print(vim.inspect(...))
end

Pack.now(function()
	Utils.fn.add_to_path("${DATA_DIR}/mason/bin")
	require("lsp")
	vim.cmd.colorscheme("custom")
end, { vscode = false })

Pack.defer(function()
	Utils.root.setup()
	Utils.format.setup()
	require("statusline").setup()
end, { vscode = false })

Pack.lazy_file(function()
	Utils.map.setup()
	require("breadcrumb").setup()
end, { vscode = false })
