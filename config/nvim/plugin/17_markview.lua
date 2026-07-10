Pack.add("OXY2DEV/markview.nvim")

Pack.when({ ft = "markdown" }, function()
	require("markview").setup()
end)
