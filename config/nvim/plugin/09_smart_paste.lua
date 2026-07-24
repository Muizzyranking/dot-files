Pack.add({ "nemanjamalesija/smart-paste.nvim" })
Pack.lazy_file(function()
	require("smart-paste").setup({})
end, "smart-paste.nvim")
