local builtin = require("telescope.builtin")
local map = vim.keymap.set
local actions = require("telescope.actions")
local open_with_trouble = function(...)
	return require("trouble.providers.telescope").open_with_trouble(...)
end
return { -- Fuzzy Finder (files, lsp, etc)
	"nvim-telescope/telescope.nvim",
	event = "VimEnter",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ -- If encountering errors, see telescope-fzf-native README for install instructions
			"nvim-telescope/telescope-fzf-native.nvim",

			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		{ "nvim-telescope/telescope-ui-select.nvim" },

		{ "nvim-tree/nvim-web-devicons" },
	},
	config = function()
		require("telescope").setup({

			-- You can put your default mappings / updates / etc. in here
			defaults = {
				mappings = {
					i = {
						["<c-t>"] = open_with_trouble,
						["<C-f>"] = actions.preview_scrolling_down,
						["<C-b>"] = actions.preview_scrolling_up,
					},
					n = {
						["q"] = actions.close,
					},
				},
			},
			-- pickers = {}
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown(),
				},
			},
		})

		-- Enable telescope extensions, if they are installed
		pcall(require("telescope").load_extension, "fzf")
		pcall(require("telescope").load_extension, "ui-select")

		map("n", "<leader>fh", builtin.help_tags, { desc = "Find Help Tags" })
		map("n", "<leader>fk", builtin.keymaps, { desc = "Find Keymaps" })
		map("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
		-- map("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
		-- map("n", "<leader>sw", builtin.grep_string, { desc = "Search current Word" })
		map("n", "<leader>fg", builtin.live_grep, { desc = "Find by Grep" })
		map("n", "<leader>fd", builtin.diagnostics, { desc = "Find Diagnostics" })
		-- map("n", "<leader>fr", builtin.resume, { desc = "Search Resume" })
		map("n", "<leader>fr", builtin.oldfiles, { desc = "Find Recent Files" })
		map("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })

		vim.keymap.set("n", "<leader>fw", function()
			builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
				winblend = 0,
				previewer = false,
			}))
		end, { desc = "Find in Current Buffer" })

		-- Also possible to pass additional configuration options.
		--  See `:help telescope.builtin.live_grep()` for information about particular keys
		vim.keymap.set("n", "<leader>fW", function()
			builtin.live_grep({
				grep_open_files = true,
				prompt_title = "Live Grep in Open Files",
			})
		end, { desc = "Find in Open Files" })

		-- Shortcut for searching your neovim configuration files
		vim.keymap.set("n", "<leader>fc", function()
			builtin.find_files({ cwd = vim.fn.stdpath("config") })
		end, { desc = "Find Config Files" })
	end,
}
