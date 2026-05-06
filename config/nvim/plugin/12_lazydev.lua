Pack.add({
	{ src = "folke/lazydev.nvim" },
	{ src = "Bilal2453/luvit-meta" },
})

Pack.on_ft({ "lua" }, function()
	Pack.deps("luvit-meta", "lazydev.nvim")
	require("lazydev").setup({
		library = {
			{ path = "luvit-meta/library", words = { "vim%.uv" } },
			{ path = "snacks.nvim", words = { "Snacks" } },
			{ path = "lua/core/pack", words = { "Pack" } },
			{ path = "lua/utils", words = { "Utils" } },
		},
	})
end, "lazydev.nvim")
