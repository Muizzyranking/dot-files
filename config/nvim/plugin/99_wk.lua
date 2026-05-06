Pack.add({ src = "folke/which-key.nvim" })

Pack.defer(function()
	require("which-key").setup({
		icons = {
			rules = {
				{ pattern = "%f[%a]ai", icon = "  ", color = "blue" },
			},
		},
		preset = "classic",
		plugins = {
			marks = true,
			registers = true,
			spelling = {
				enabled = false,
			},
			presets = {
				operators = true,
				motions = true,
				text_objects = true,
				windows = true,
				nav = true,
				z = true,
				g = true,
			},
		},
		defaults = {},
		spec = {
			{
				mode = { "n", "v" },
				{ "<leader><tab>", group = "tabs", icon = { icon = "󰭋 ", color = "orange" } },
				{ "<leader>c", group = "code" },
				{ "<leader>g", group = "git" },
				{ "<leader>gh", group = "hunks" },
				{ "<leader>q", group = "quit/session" },
				{ "<leader>s", group = "search" },
				{ "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
				{ "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
				{ "[", group = "prev" },
				{ "]", group = "next" },
				{ "g", group = "goto" },
				{ "gs", group = "surround" },
				{ "z", group = "fold" },
				{ "<leader>b", group = "buffer", icon = { icon = " " } },
				{
					"<leader>w",
					group = "windows",
					proxy = "<c-w>",
					expand = function()
						return require("which-key.extras").expand.win()
					end,
				},
				-- better descriptions
				{ "gx", desc = "Open with system app" },
			},
		},
	})
end, "which-key.nvim")

Utils.map.set({
	{
		"<leader>?",
		function()
			require("which-key").show({ global = false })
		end,
		desc = "Buffer Keymaps (which-key)",
	},
})
