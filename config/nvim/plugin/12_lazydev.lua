Pack.add({ "folke/lazydev.nvim", "Bilal2453/luvit-meta" })

Pack.when({ ft = { "lua" } }, function()
	require("lazydev").setup({
		library = {
			{ path = "luvit-meta/library", words = { "vim%.uv" } },
			{ path = "snacks.nvim", words = { "Snacks" } },
			{ path = "lua/core/pack", words = { "Pack" } },
			{ path = "lua/utils", words = { "Utils" } },
		},
	})
end)
