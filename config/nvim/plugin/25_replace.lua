Pack.add({
	{ src = "MagicDuck/grug-far.nvim" },
	{ src = "smjonas/inc-rename.nvim" },
})

Pack.on_key({
	{
		"<leader>sr",
		function()
			local grug = require("grug-far")
			local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
			grug.open({
				visualSelectionUsage = "operate-within-range",
				prefills = {
					filesFilter = ext and ext ~= "" and "*." .. ext or nil,
				},
			})
		end,
		mode = { "n", "v" },
		desc = "Search and Replace",
	},
	{
		"<leader>sW",
		function()
			local grug = require("grug-far")
			grug.open({
				prefills = { search = vim.fn.expand("<cword>") },
			})
		end,
		desc = "Search and Replace word under cursor",
	},
	{
		"<leader>sf",
		function()
			local grug = require("grug-far")
			grug.open({
				prefills = { paths = vim.fn.expand("%p") },
			})
		end,
		desc = "Search and Replace (in current file)",
	},
}, function()
	require("grug-far").setup({
		headerMaxWidth = 80,
		transient = true,
		visualSelectionUsage = "operate-within-range",
	})
end, "grug-far.nvim")

Pack.on_key({
	{
		"<leader>cr",
		function()
			return ":IncRename" .. " " .. vim.fn.expand("<cword>")
		end,
		desc = "Rename",
		icon = { icon = "󰑕 ", color = "orange" },
		has = "rename", -- only set if lsp supports rename
		expr = true,
		silent = false,
	},
}, function()
	require("inc_rename").setup({
		hl_group = "Substitute",
		preview_empty_name = false,
		show_message = true,
		save_in_cmdline_history = true,
	})
end, "inc-rename.nvim")
