return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		transparent_mode = false,
	},
	config = function(_, opts)
		vim.cmd("colorscheme gruvbox")
	end,
}
