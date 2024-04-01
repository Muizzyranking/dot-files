return { -- Adds git related signs to the gutter, as well as utilities for managing changes
	"lewis6991/gitsigns.nvim",
    lazy = true,
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
		},
	},
	{
		{
			"kdheepak/lazygit.nvim",
            cmd = "LazyGit",
			dependencies = {
				"nvim-telescope/telescope.nvim",
				"nvim-lua/plenary.nvim",
			},
			config = function()
				require("telescope").load_extension("lazygit")
			end,
		},
	},
	{
		"akinsho/toggleterm.nvim",
		cmd = { "ToggleTerm", "TermExec" },
		lazy = true,
		opts = {
			highlights = {
				Normal = { link = "Normal" },
				NormalNC = { link = "NormalNC" },
				NormalFloat = { link = "NormalFloat" },
				FloatBorder = { link = "FloatBorder" },
				StatusLine = { link = "StatusLine" },
				StatusLineNC = { link = "StatusLineNC" },
				WinBar = { link = "WinBar" },
				WinBarNC = { link = "WinBarNC" },
			},
			size = 10,
			on_create = function()
				vim.opt.foldcolumn = "0"
				vim.opt.signcolumn = "no"
			end,
			open_mapping = [[<C-_>]],
			shading_factor = 2,
			direction = "float",
			float_opts = { border = "rounded" },
		},
	},
}
