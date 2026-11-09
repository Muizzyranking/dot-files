Pack.add("muizzyranking/mdview-nvim")

local keys = {
	{ "<leader>mp", "MdViewToggle", desc = "Toggle markdown preview" },
}

Pack.when({ ft = "markdown", keys = keys }, function()
	require("mdview").setup({})
end)
