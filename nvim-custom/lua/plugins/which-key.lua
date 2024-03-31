return { -- Useful plugin to show you pending keybinds.
	"folke/which-key.nvim",
	event = "VimEnter", -- Sets the loading event to 'VimEnter'
	config = function() -- This is the function that runs, AFTER loading
		local wk = require("which-key")
		wk.setup()
		wk.register({
			mode = { "n", "v" },
			["g"] = { name = "+goto" },
			["gs"] = { name = "+surround" },
			["z"] = { name = "+fold" },
			["]"] = { name = "+next" },
			["["] = { name = "+prev" },
			["<leader>b"] = { name = "+buffer" },
			["<leader>c"] = { name = "code" },
			["<leader>f"] = { name = "+find" },
			["<leader>g"] = { name = "+git" },
			["<leader>w"] = { name = "+window" },
			-- ["<leader>gh"] = { name = "+HUNKS" },
			-- ["<leader>q"] = { name = "+quit/session" },
			-- ["<leader>s"] = { name = "+search" },
			["<leader>x"] = { name = "+DIAGNOSTICS/quickfix" },
		})
	end,
}
