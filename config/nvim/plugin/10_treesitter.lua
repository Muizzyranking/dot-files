Pack.on_changed("nvim-treesitter", function()
	vim.cmd("TSUpdate")
end, "update")

Pack.add({
	{ "https://github.com/nvim-treesitter/nvim-treesitter", vscode = true },
	"https://github.com/windwp/nvim-ts-autotag",
	{ "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", vscode = true },
})

Pack.when({ lazy_file = true, defer = true, vscode = true }, function()
	local opts = {
		ensure_installed = Settings.get("parsers", {}),
	}
	Utils.treesitter.incr.attach({
		init_selection = "<CR>",
		node_incremental = "<CR>",
		scope_incremental = "<C-n>",
		node_decremental = "<BS>",
	})
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
			if Utils.fn.is_in_vscode() then
				return
			end
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
end, "nvim-treesitter")

Pack.when({ lazy_file = true }, function()
	require("nvim-ts-autotag").setup()
end)

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
end, { vscode = true })
