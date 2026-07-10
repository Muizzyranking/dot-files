Pack.add({
	"Bekaboo/dropbar.nvim",
	"folke/flash.nvim",
	"folke/persistence.nvim",
	"christoomey/vim-tmux-navigator",
	"Wansmer/treesj",
	"HiPhish/rainbow-delimiters.nvim",
	"folke/todo-comments.nvim",
})

Pack.when({ event = "LspAttach" }, function()
	local dropbar = require("dropbar")
	local sources = require("dropbar.sources")
	local utils = require("dropbar.utils")
	dropbar.setup({
		bar = {
			sources = function(buf, _)
				if vim.bo[buf].ft == "markdown" then
					return { sources.markdown }
				end
				if vim.bo[buf].buftype == "terminal" then
					return { sources.terminal }
				end
				return { utils.source.fallback({ sources.lsp }) }
			end,
		},
	})
end)

Pack.defer(function()
	require("flash").setup({
		prompt = { prefix = { { "🔍", "Flash" } } },
		modes = { char = { jump_labels = true } },
	})
	Utils.map.set({
    -- stylua: ignore start
		{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
		{ "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
		{ "r", mode = "n", function() require("flash").remote() end, desc = "Remote Flash" },
		{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
		{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
		-- stylua: ignore end
	})
end)

Pack.defer(function()
	require("persistence").setup()
	-- local argc = vim.fn.argc()
	-- local argv0 = argc > 0 and vim.fn.argv(0) or nil
	--
	-- if argv0 and vim.islist(argv0) then
	-- 	argv0 = argv0[1]
	-- end
	-- ---@diagnostic disable-next-line: param-type-mismatch
	-- if argc == 0 or (argc == 1 and argv0 and vim.fn.isdirectory(argv0) == 1) then
	-- 	require("persistence").load()
	-- 	vim.schedule(function()
	-- 		vim.api.nvim_exec_autocmds("FileType", {
	-- 			buffer = vim.api.nvim_get_current_buf(),
	-- 			modeline = false,
	-- 		})
	-- 	end)
	-- end
	Utils.map.set({
		{
			"<leader>qs",
			function()
				require("persistence").load()
			end,
			desc = "Restore Session",
		},
		{
			"<leader>ql",
			function()
				require("persistence").load({ last = true })
			end,
			desc = "Restore Last Session",
		},
		{
			"<leader>qd",
			function()
				require("persistence").stop()
			end,
			desc = "Don't Save Current Session",
		},
	})
end)

if Utils.fn.is_in_tmux() then
	Pack.defer(function()
		Utils.map.set({
			{ "<c-h>", "<cmd>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
		})
	end)
end

Pack.when({
	keys = {
		{
			"gs",
			function()
				require("treesj").toggle()
			end,
			desc = "Join/Split Lines",
		},
	},
}, function()
	require("treesj").setup({
		use_default_keymaps = false,
		max_join_length = 120,
		cursor_behavior = "hold",
		notify = true,
		dot_repeat = true,
	})
end)

Pack.when({ event = { "BufRead", "BufReadPre" } }, function()
	require("rainbow-delimiters.setup").setup({ priority = { [""] = 110 } })
end)

Pack.when({
	lazy_file = true,
	keys = {
		{
			"]t",
			function()
				require("todo-comments").jump_next()
			end,
			desc = "Next Todo Comment",
		},
		{
			"[t",
			function()
				require("todo-comments").jump_prev()
			end,
			desc = "Previous Todo Comment",
		},
		{ "<leader>xt", "TodoTrouble<cr>", desc = "Todo (Trouble)" },
		{ "<leader>xT", "TodoTrouble keywords=TODO,FIX,FIXME", desc = "Todo/Fix/Fixme (Trouble)" },
	},
}, function()
	require("todo-comments").setup()
end)
