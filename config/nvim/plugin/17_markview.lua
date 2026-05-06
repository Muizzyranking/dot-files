Pack.add({ src = "OXY2DEV/markview.nvim" })

Pack.on_ft({ "markdown" }, function()
	require("markview").setup()
end, "markview.nvim")
