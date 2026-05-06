Pack.on_changed("blink.cmp", function(params)
	vim.notify("Building blink.cmp", vim.log.levels.INFO)
	local obj = vim.system({ "cargo", "build", "--release" }, { cwd = params.path }):wait()
	local c = obj.code
	Utils.notify[c == 0 and "info" or "error"]("Building blink.cmp " .. (c == 0 and "done" or "failed"))
end)

Pack.on_changed("copilot.lua", function()
	vim.cmd("Copilot auth")
end)

Pack.add({
	{ src = "rafamadriz/friendly-snippets" },
	{ src = "zbirenbaum/copilot.lua" },
	{ src = "giuxtaposition/blink-cmp-copilot" },
	{ src = "saghen/blink.cmp" },
})

Pack.on_event({ "BufReadPost" }, function()
	require("copilot").setup({
		suggestion = { enabled = false },
		panel = { enabled = false },
		filetypes = {
			markdown = true,
			help = true,
			gitcommit = true,
			sh = function()
				local filename = vim.fs.basename(Utils.fn.get_filepath())
				if
					string.match(filename, "^%.env")
					or string.match(filename, "^%.env.*")
					or string.match(filename, "^%.secret.*")
					or string.match(filename, "^%id_rsa.*")
				then
					return false
				end
				return true
			end,
		},
	})
end, "copilot.lua")

Pack.on_event({ "InsertEnter", "CmdlineEnter" }, function()
	Pack.deps("copilot.lua", "blink.cmp")
	Pack.deps("blink-cmp-copilot", "blink.cmp")
	Pack.deps("friendly-snippets", "blink.cmp")
	local opts = {
		keymap = {
			preset = "enter",
			-- I use <c-e> to go to the end of the line in insert mode
			["<C-e>"] = {},
			-- a as in abort makes sense to me
			["<C-a>"] = { "hide", "fallback" },
			["<C-y>"] = { "select_and_accept" },
		},
		appearance = {
			use_nvim_cmp_as_default = false,
			nerd_font_variant = "mono",
			kind_icons = Utils.icons.kinds,
		},
		signature = { enabled = false },
		sources = {
			default = { "lsp", "copilot", "path", "snippets", "buffer" },
			providers = {
				copilot = {
					name = "copilot",
					module = "blink-cmp-copilot",
					kind = "Copilot",
					score_offset = 100,
					async = true,
				},
			},
		},
		cmdline = {
			enabled = true,
			keymap = { preset = "cmdline" },
			completion = {
				list = { selection = { preselect = false } },
				menu = {
					auto_show = function(_)
						return vim.fn.getcmdtype() == ":"
					end,
				},
				ghost_text = { enabled = true },
			},
		},
		fuzzy = { implementation = "prefer_rust" },
		completion = {
			list = { selection = { preselect = true, auto_insert = false } },
			accept = {
				auto_brackets = { enabled = true },
			},
			menu = {
				border = "rounded",
				auto_show = function(ctx)
					return ctx.mode ~= "cmdline" or not vim.tbl_contains({ "/", "?" }, vim.fn.getcmdtype())
				end,
				winblend = 0,
				draw = {
					treesitter = { "lsp" },
					columns = { { "kind_icon" }, { "label", "label_description" }, { "kind", gap = 1 } },
					components = {},
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
				window = { border = "rounded", winblend = 0 },
			},
			ghost_text = { enabled = true },
		},
	}
	local disabled_filetypes = { "prompt" }
	opts.enabled = function()
		return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype) and vim.b.completion ~= false
	end

	for _, provider in pairs(opts.sources.providers or {}) do
		if provider.kind then
			local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
			local kind_idx = #CompletionItemKind + 1

			CompletionItemKind[kind_idx] = provider.kind
			CompletionItemKind[provider.kind] = kind_idx

			local transform_items = provider.transform_items
			provider.transform_items = function(ctx, items)
				items = transform_items and transform_items(ctx, items) or items
				for _, item in ipairs(items) do
					item.kind = kind_idx or item.kind
				end
				return items
			end
			provider.kind = nil
		end
	end
	require("blink.cmp").setup(opts)
end, "blink.cmp")
