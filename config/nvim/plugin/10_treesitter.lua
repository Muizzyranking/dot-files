Pack.on_changed("nvim-treesitter", function()
	vim.cmd("TSUpdate")
end, "update")

Pack.add({
	{ src = "nvim-treesitter/nvim-treesitter", name = "nvim-treesitter" },
	{ src = "windwp/nvim-ts-autotag" },
	{ src = "nvim-treesitter/nvim-treesitter-textobjects" },
})

Pack.lazy("nvim-treesitter", {
	lazy_file = true,
	defer = true,
	config = function()
		local opts = {
			ensure_installed = {
				"c",
				"cpp",
				"vim",
				"vimdoc",
				"query",
				"python",
				"toml",
				"rst",
				"regex",
				"yaml",
				"diff",
				"jsdoc",
				"luadoc",
				"lua",
				"luadoc",
				"luap",
				"python",
				"ninja",
				"rst",
				"htmldjango",
				"vim",
				"xml",
				"puppet",
				"typescript",
				"javascript",
				"tsx",
				"bash",
				"hyprlang",
				"rasi",
				"git_config",
				"cpp",
				"go",
				"gomod",
				"gowork",
				"gosum",
				"html",
				"css",
				"http",
				"graphql",
				"json",
				"json5",
				"jsonc",
				"rust",
				"ron",
				"php",
				"phpdoc",
				"qml",
				"qmldir",
				"qmljs",
				"dockerfile",
			},
			incremental_selection = {
				keymaps = {
					init_selection = "<CR>",
					node_incremental = "<CR>",
					scope_incremental = "<C-n>",
					node_decremental = "<BS>",
				},
			},
		}
		Utils.treesitter.setup(opts)
		local ts = require("nvim-treesitter")
		ts.setup()

		-- Only install parsers that are not already present.
		local missing = vim.tbl_filter(function(lang)
			return not Utils.treesitter.have(lang)
		end, opts.ensure_installed or {})

		if #missing > 0 then
			ts.install(missing, { summary = true }):await(function()
				Utils.treesitter.get_installed(true)
			end)
		end

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(ev)
				local ft = ev.match
				if not Utils.treesitter.have(ft) then
					return
				end
				pcall(vim.treesitter.start)
				vim.opt.indentexpr = "v:lua.require('utils.treesitter').indentexpr()"
				vim.o.foldmethod = "expr"
				vim.o.foldexpr = "v:lua.require('utils.treesitter').foldexpr()"
			end,
		})
	end,
})

Pack.on_lazy_file(function()
	require("nvim-ts-autotag").setup()
end, "nvim-ts-autotag")

Pack.defer(function()
	require("nvim-treesitter-textobjects").setup()
	local keys = function()
		local moves = {
			goto_next_start = {
				["]f"] = "@function.outer",
				["]c"] = "@class.outer",
				["]a"] = "@parameter.inner",
			},
			goto_next_end = {
				["]F"] = "@function.outer",
				["]C"] = "@class.outer",
				["]A"] = "@parameter.inner",
			},
			goto_previous_start = {
				["[f"] = "@function.outer",
				["[c"] = "@class.outer",
				["[a"] = "@parameter.inner",
			},
			goto_previous_end = {
				["[F"] = "@function.outer",
				["[C"] = "@class.outer",
				["[A"] = "@parameter.inner",
			},
			goto_next = { ["]o"] = "@conditional.outer" },
			goto_previous = { ["[o"] = "@conditional.outer" },
		}

		local ret = {}
		for method, keymaps in pairs(moves) do
			for key, query in pairs(keymaps) do
				local desc = query:gsub("@", ""):gsub("%..*", "")
				desc = desc:sub(1, 1):upper() .. desc:sub(2)
				desc = (key:sub(1, 1) == "[" and "Prev " or "Next ") .. desc
				desc = desc .. (key:sub(2, 2) == key:sub(2, 2):upper() and " End" or " Start")

				ret[#ret + 1] = {
					key,
					function()
						if vim.wo.diff and key:find("[cC]") then
							vim.cmd("normal! " .. key)
							return
						end
						require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
					end,
					desc = desc,
					mode = { "n", "x", "o" },
				}
			end
		end
		return ret
	end
	Utils.map.set(keys())
end, "nvim-treesitter-textobjects")
