Pack.add({ src = "folke/snacks.nvim" })

local notify = Utils.notify.create({ title = "Snacks" })

local function get_unsaved_buffers()
	local buffers = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
			local name = vim.api.nvim_buf_get_name(buf)
			local display_name = name
			if name == "" then
				display_name = "[No Name]"
			else
				display_name = vim.fn.fnamemodify(name, ":~:.")
			end
			table.insert(buffers, {
				buf = buf,
				text = display_name,
				filename = name,
				idx = buf,
			})
		end
	end
	return buffers
end

local function unsaved_buffers_picker()
	local initial_buffers = get_unsaved_buffers()
	if #initial_buffers == 0 then
		notify.info("No unsaved buffers")
		return
	end

	return Snacks.picker({
		title = "Unsaved Buffers",
		finder = function()
			return get_unsaved_buffers()
		end,
		format = function(item)
			local ret = {}
			local icon, icon_hl = Snacks.util.icon(item.filename)
			ret[#ret + 1] = { icon .. " ", icon_hl }
			ret[#ret + 1] = { item.text }
			return ret
		end,
		actions = {
			confirm = function(picker, item)
				picker:close()
				if not item then
					return
				end
				vim.api.nvim_set_current_buf(item.buf)
			end,
			save = function(picker)
				local items = picker:selected({ fallback = true })
				if not items or #items == 0 then
					notify.info("No buffer selected")
					return
				end
				local saved_count = 0
				local failed_count = 0
				for _, item in ipairs(items) do
					local ok, _ = pcall(function()
						vim.api.nvim_buf_call(item.buf, function()
							vim.cmd("write")
						end)
					end)
					if ok then
						saved_count = saved_count + 1
					else
						failed_count = failed_count + 1
					end
				end
				local lines = {}
				table.insert(lines, "**Saved** " .. saved_count .. " buffer(s)")
				table.insert(lines, "**Failed** to save " .. failed_count .. " buffer(s)")
				notify.info(lines)
				picker:find({
					on_done = function()
						if picker:count() == 0 then
							picker:close()
							notify.info("All buffers saved!")
						end
					end,
				})
			end,
			save_all = function(picker)
				local buffers = get_unsaved_buffers()
				local saved_count = 0
				for _, buf_item in ipairs(buffers) do
					local success = pcall(function()
						vim.api.nvim_buf_call(buf_item.buf, function()
							vim.cmd("write")
						end)
					end)
					if success then
						saved_count = saved_count + 1
					end
				end
				notify.info("Saved " .. saved_count .. " buffer(s)")
				picker:find({
					on_done = function()
						if picker:count() == 0 then
							picker:close()
						end
					end,
				})
			end,
		},
		---@diagnostic disable-next-line: assign-type-mismatch
		layout = { preset = "drop", preview = false },
		on_show = function()
			vim.cmd("stopinsert")
		end,
		win = {
			input = {
				keys = {
					["<c-s>"] = { "save", mode = { "n", "i" } },
					["<c-a>"] = { "save_all", mode = { "n", "i" } },
				},
			},
		},
	})
end

local notifier = {
	enabled = true,
	timeout = 3000,
	width = { min = 40, max = 0.4 },
	height = { min = 1, max = 0.6 },
	margin = { top = 0, right = 1, bottom = 0 },
	padding = true,
	sort = { "level", "added" },
	level = vim.log.levels.TRACE,
	icons = {
		error = " ",
		warn = " ",
		info = " ",
		debug = " ",
		trace = " ",
	},
	keep = function()
		return vim.fn.getcmdpos() > 0
	end,
	filter = function(notif)
		local ignores = { "^client.supports_method is deprecated" }
		return not vim.iter(ignores):any(
			---@param pat string
			function(pat)
				return string.find(notif.msg, pat) ~= nil
			end
		)
	end,
	style = "compact",
	top_down = false,
	date_format = "%R",
	---@type string|boolean
	more_format = " ↓ %d lines ",
	refresh = 50,
}
local indent = {
	indent = {
		enabled = true,
		char = "│",
		blank = " ",
		only_scope = false,
		only_current = false,
		hl = "SnacksIndent",
	},
	animate = {
		enabled = true,
		style = "out",
		easing = "linear",
		duration = {
			step = 20,
			total = 500,
		},
	},
	scope = {
		enabled = true,
		char = "│",
		underline = false,
		only_current = false,
		hl = "SnacksIndentScope",
	},
	chunk = {
		enabled = false,
		only_current = true,
		hl = "SnacksIndentChunk",
		char = {
			-- corner_top = "┌",
			-- corner_bottom = "└",
			corner_top = "╭",
			corner_bottom = "╰",
			horizontal = "─",
			vertical = "│",
			arrow = ">",
		},
	},
	blank = {
		char = " ",
		hl = "SnacksIndentBlank",
	},
	filter = function(buf)
		return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ""
	end,
	priority = 200,
}
local explorer = {
	on_show = function()
		Snacks.notifier.hide()
	end,
	on_close = function() end,
	format = function(item, picker)
		-- show changed icon for modified buffers in explorer
		local ret = require("snacks.picker.format").file(item, picker)
		local item_path = Snacks.picker.util.path(item)
		local bufnr = vim.fn.bufnr(item_path)
		if bufnr ~= -1 and vim.bo[bufnr].modified then
			table.insert(ret, { "●", hl = "DiagnosticWarn" })
		end
		return ret
	end,
	layout = {
		layout = { position = "right" },
		preset = "sidebar",
		hidden = { "input" },
		auto_hide = { "input" },
	},
	include = { "*.zsh*", ".env.*", ".env", ".gitignore", ".dockerignore" },
	-- exclude = { "node_modules", "venv", ".venv" },
	supports_live = true,
	tree = true,
	watch = true,
	diagnostics_open = false,
	git_status_open = false,
	follow_file = true,
	auto_close = false,
	jump = { close = false },
	formatters = {
		file = { filename_only = true },
		severity = { pos = "right" },
	},
	matcher = { sort_empty = false, fuzzy = true },
	actions = {},
	win = {
		list = {
			keys = {
				["<c-c>"] = "",
				["<c-h>"] = nil,
				["s"] = "edit_vsplit",
				["S"] = "edit_split",
			},
		},
	},
}

local layouts = {
	drop = {
		layout = {
			preview = false,
			backdrop = false,
			width = 0.4,
			min_width = 80,
			height = 0.6,
			border = "none",
			box = "vertical",
			{ win = "preview", title = "{preview}", height = 0.4, border = "rounded" },
			{
				box = "vertical",
				border = "rounded",
				title = "{title} {live} {flags}",
				title_pos = "center",
				{ win = "input", height = 1, border = "bottom" },
				{ win = "list", border = "none" },
			},
		},
	},
}
local picker = {
	prompt = " ",
	ui_select = true,
	layout = { preset = "ivy" },
	sources = {
		explorer = explorer,
		files = {
			exclude = { ".git", ".cache", "node_modules", "venv", ".venv", ".pytest_cache" },
			actions = {},
		},
		buffers = {
			sort_lastused = true,
			hidden = false,
			ignore_filetype = {},
			focus = "list",
			win = {
				input = { keys = { ["dd"] = "bufdelete", ["<c-x>"] = { "bufdelete", mode = { "n", "i" } } } },
				list = {
					keys = {
						["dd"] = "bufdelete",
						["s"] = "edit_vsplit",
						["S"] = "edit_split",
					},
				},
			},
			layout = { preset = "drop", preview = false },
		},
	},
	focus = "input",
	matcher = {
		fuzzy = true,
		frecency = true,
		history_bonus = true,
	},
	jump = { reuse_win = false, match = false },
	layouts = layouts,
	actions = {},
	win = {
		input = {
			keys = {
				["<C-h>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
				["s"] = "edit_vsplit",
				["S"] = "edit_split",
			},
			b = { completion = false },
		},
		list = { keys = {} },
	},
}

Pack.now(function()
	require("snacks").setup({
		explorer = {
			on_show = function()
				Snacks.notifier.hide()
			end,
		},
		input = { enabled = true },
		indent = indent,
		dashboard = { enabled = false },
		picker = picker,
		notifier = notifier,
		bigfile = { enabled = true },
		image = { enabled = true },
		quickfile = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
		scroll = { enabled = true },
		lazygit = {
			win = {
				bo = { filetype = "lazygit" },
				keys = { ["<C-h>"] = { "<c-s-w>", mode = { "i", "t" }, expr = true, desc = "delete word" } },
			},
			config = {
				git = { overrideGpg = true },
				promptToReturnFromSubprocess = false,
			},
		},
		styles = {
			input = { keys = { i_c_h = { "<c-h>", "<c-s-w>", mode = "i", expr = true } } },
		},
	})
	local keys = {
    -- stylua: ignore start
		{ "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History" },
		{ "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
		{ "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
		{ "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
		{
			"z=",
			function()
				Snacks.picker.spelling({
					on_show = function()
						vim.cmd("stopinsert")
					end,
				})
			end,
			desc = "Spell suggestions",
		},
		{
			"<leader>fb",
			function()
				Snacks.picker.buffers({
					on_show = function()
						vim.cmd("stopinsert")
					end,
				})
			end,
			desc = "Buffers",
		},
		{ "<leader>fB", unsaved_buffers_picker, desc = "Buffers" },
		{ "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files (cwd)" },
		{ "<leader>fF", function() Snacks.picker.files({ cwd = Utils.root() }) end, desc = "Find Files (root)" },
		{ "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep" },
		{ "<leader>sw", function() Snacks.picker.grep_word() end, mode = { "n", "x" }, desc = "Search word" },
		{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
		{ "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent files (cwd)" },
		{ "<leader>fG", function() Snacks.picker.grep_buffers() end, desc = "Grep in Open Buffers" },
		{ "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
		{ "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
		{ "<leader>sm", function() Snacks.picker.man() end, desc = "Man Pages" },
		{
			"<leader>fc",
			function()
				Snacks.picker.resume({ exclude = { "explorer", "notifications" } })
			end,
			desc = "Continue from last search",
		},
		{ "<leader>e", function() Snacks.explorer({ cwd = Utils.root() }) end, desc = "File explorer (root)" },
		{ "<leader>E", function() Snacks.explorer() end, desc = "File explorer (cwd)" },
		{
			"<leader>fe",
			function()
				if Snacks.picker.get({ source = "explorer" })[1] ~= nil then
					Snacks.picker.get({ source = "explorer" })[1]:focus()
				else
					Snacks.explorer({ cwd = Utils.root() })
				end
			end,
			desc = "Explorer Snacks (root dir)",
		},
		-- stylua: ignore end
	}
	Utils.map.set(keys)
	Utils.map.add_to_wk({
		{
			"<leader>f",
			icon = { icon = " ", color = "green" },
			desc = "find",
		},
	})
end, "snacks.nvim")
