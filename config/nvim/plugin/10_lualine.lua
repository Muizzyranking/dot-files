vim.o.laststatus = 3
Pack.add({ "nvim-lualine/lualine.nvim" })

local W = { full = 120, medium = 90 }

local function at_least(n)
	return function()
		return vim.o.columns >= n
	end
end

local function stbufnr()
	return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

local function theme_from(c)
	local function mode(bg)
		return {
			a = { fg = c.bg_dark, bg = bg, gui = "bold" },
			b = { fg = c.fg, bg = c.surface },
			c = { fg = c.fg, bg = c.none },
		}
	end

	return {
		normal = mode(c.red),
		insert = mode(c.green),
		visual = mode(c.blue),
		replace = mode(c.orange),
		command = mode(c.cyan),
		inactive = {
			a = { fg = c.fg_dimmer, bg = c.none },
			b = { fg = c.fg_dimmer, bg = c.none },
			c = { fg = c.fg_dimmer, bg = c.none },
		},
	}
end

local function truncate_lsp_name(name)
	if #name < 10 then
		return name
	end
	if name:find("_") then
		name = name:match("([^_]+)")
	elseif name:find("language") or name:find("ls") then
		name = name:match("(%S+)%-?language") or name:match("(%S+)%-?ls") or name
	end
	if #name > 10 then
		name = name:sub(1, 10) .. "…"
	end
	return name
end

local function get_lsps()
	local buf_clients = Utils.lsp.get_clients({ bufnr = 0 })
	local names = {}
	for _, client in pairs(buf_clients) do
		if client.name ~= "conform" and client.name ~= "copilot" then
			table.insert(names, client.name)
		end
	end
	if #names == 0 then
		return ""
	end

	-- Medium width: show only the first server, shortened. Full width: all of them.
	if vim.o.columns < W.full then
		names = { truncate_lsp_name(names[1]) }
	elseif #names > 2 then
		for i, name in ipairs(names) do
			names[i] = truncate_lsp_name(name)
		end
	end

	local lsp_icon = Utils.icons.lsp.active or ""
	return ("%s %s"):format(lsp_icon, Utils.fn.ensure_string(names))
end

local function truncate_path(path, max_len)
	if #path <= max_len then
		return path
	end
	local name = vim.fn.fnamemodify(path, ":t")
	local parent = vim.fn.fnamemodify(path, ":h:t")
	local short = (parent ~= "." and parent ~= "") and (parent .. "/" .. name) or name
	if #short <= max_len then
		return short
	end
	return "…" .. name:sub(-(max_len - 1))
end

local function filepath_text()
	local buf = stbufnr()
	local full = vim.api.nvim_buf_get_name(buf)
	local file_icon = Utils.icons.file
	local cols = vim.o.columns

	if full == "" then
		return "󰈚 [No Name]"
	end

	local name = vim.fn.fnamemodify(full, ":t")
	local rel = vim.fn.fnamemodify(full, ":~:.")
	local max_len = cols > 120 and 60 or cols > 80 and 40 or 20
	local display = truncate_path(rel, max_len)

	local icon = "󰈚"
	local ok, MiniIcons = pcall(require, "mini.icons")
	if ok then
		local ic = MiniIcons.get("file", name)
		if ic and ic ~= "" then
			icon = ic
		end
	end

	local bo = vim.bo[stbufnr()]
	local mod_icon = bo.modified and file_icon.modified or file_icon.unmodified
	local ro_icon = bo.readonly and file_icon.readonly or ""
	local ex_icon = Utils.fn.is_executable(full) and " 󰒃" or ""

	return string.format("%s %s%s%s%s", icon, display, mod_icon, ro_icon, ex_icon)
end

local function filepath_state()
	local buf = stbufnr()
	local full = vim.api.nvim_buf_get_name(buf)
	if vim.bo[buf].modified then
		return "modified"
	elseif full ~= "" and Utils.fn.is_executable(full) then
		return "exec"
	end
	return "normal"
end

local function filepath_hl(c)
	local state = filepath_state()
	if state == "modified" then
		return { fg = c.orange }
	elseif state == "exec" then
		return { fg = c.green }
	end
	return { fg = c.fg }
end

local function get_buffers()
	local buffers = vim.fn.getbufinfo({ buflisted = 1 })
	local modified_count = 0
	for _, buf in ipairs(buffers) do
		if vim.bo[buf.bufnr].modified then
			modified_count = modified_count + 1
		end
	end
	local icon = Utils.icons.ui.buffer
	local modified_indicator = modified_count > 0 and (" " .. modified_count) or ""
	return string.format("%s%d%s", icon, #buffers, modified_indicator)
end

local function progress()
	local current_line = vim.fn.line(".")
	local total_lines = vim.fn.line("$")
	local chars = { "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
	local index = math.ceil((current_line / total_lines) * #chars)
	return chars[math.max(1, math.min(index, #chars))]
end

local function get_snacks()
	local filetype = vim.bo.filetype
	local title = filetype
	local meta = ""

	local picker = nil
	if filetype == "snacks_picker_list" or filetype == "snacks_picker_input" then
		picker = Snacks.picker.get()[1]
	end

	if filetype == "snacks_picker_list" then
		title = "🍿 Explorer"
		meta = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
	elseif filetype == "snacks_picker_input" then
		if picker then
			local input = picker.input and picker.input:get() or ""
			local count = #picker:items()
			title = ("🍿 Picker (%s)"):format(picker.title or "")
			meta = input ~= "" and (" " .. input .. ": " .. count .. " results") or (count .. " results")
		else
			title = "🍿 Picker"
		end
	end

	return title, meta
end

local function search_count()
	if vim.v.hlsearch == 0 or vim.fn.getreg("/") == "" then
		return ""
	end
	local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 50 })
	if not ok or not result or result.total == 0 then
		return ""
	end
	if result.incomplete == 1 then
		return " ?/?"
	end
	return string.format(" %d/%d", result.current, result.total)
end

local rec_timer, rec_blink = nil, false

local function macro_text()
	local reg = vim.fn.reg_recording()
	if reg == "" then
		return ""
	end
	local dot = rec_blink and "●" or "○"
	return string.format("%s @%s", dot, reg)
end

local function macro_setup()
	local uv = vim.uv or vim.loop

	local function set_timer()
		local rec = vim.fn.reg_recording() ~= ""
		if rec and not rec_timer then
			rec_blink = true
			rec_timer = uv.new_timer()
			if rec_timer then
				rec_timer:start(
					0,
					500,
					vim.schedule_wrap(function()
						rec_blink = not rec_blink
						vim.cmd.redrawstatus()
					end)
				)
			end
		elseif not rec and rec_timer then
			rec_timer:stop()
			rec_timer:close()
			rec_timer = nil
			rec_blink = false
		end
	end

	vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
		callback = function()
			set_timer()
			vim.cmd.redrawstatus()
		end,
	})
end

local function build_opts(c)
	local icons = Utils.icons

	local copilot_status_icons = {
		[""] = icons.kinds.Copilot,
		["Normal"] = icons.kinds.Copilot,
		["Warning"] = " ",
		["InProgress"] = " ",
		["Error"] = " ",
	}
	local copilot_colors = {
		[""] = c.orange,
		["Normal"] = c.orange,
		["Warning"] = c.warning,
		["InProgress"] = c.warning,
		["Error"] = c.error,
	}

	local function copilot_status()
		local ok, status = pcall(function()
			return require("copilot.status").data
		end)
		if not ok or not status then
			return nil
		end
		return status.status
	end

	local opts = {
		options = {
			theme = theme_from(c),
			globalstatus = true,
			disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
			component_separators = { left = "", right = "" },
			section_separators = { right = "", left = "" },
		},
		sections = {
			lualine_a = {
				{
					function()
						local raw = vim.api.nvim_get_mode().mode
						return icons.modes[raw] or icons.ui.Target
					end,
					padding = { left = 2, right = 1 },
				},
			},
			lualine_b = {
				{ "branch", color = { gui = "italic" } },
				{
					filepath_text,
					color = function()
						return filepath_hl(c)
					end,
				},
			},
			lualine_c = {
				{
					function()
						local root = Utils.root.get()
						if not root then
							return ""
						end
						return string.format("󱉭 %s", vim.fn.fnamemodify(root, ":t"))
					end,
					cond = at_least(W.full),
				},
				{
					"diff",
					cond = at_least(W.medium),
					symbols = {
						added = icons.git.added,
						modified = icons.git.modified,
						removed = icons.git.removed,
					},
					source = function()
						local gs = vim.b.gitsigns_status_dict
						if gs then
							return { added = gs.added, modified = gs.changed, removed = gs.removed }
						end
					end,
				},
				{
					"diagnostics",
					symbols = {
						error = icons.diagnostics.Error,
						warn = icons.diagnostics.Warn,
						info = icons.diagnostics.Info,
						hint = icons.diagnostics.Hint,
					},
				},
			},
			lualine_x = {
				{
					search_count,
					color = { fg = c.cyan },
				},
				{
					get_buffers,
					cond = at_least(W.medium),
					color = function()
						local has_modified = false
						for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
							if vim.bo[buf.bufnr].modified then
								has_modified = true
								break
							end
						end
						return has_modified and { fg = c.warning, gui = "bold" } or { fg = c.fg_dimmer }
					end,
					on_click = function()
						Snacks.picker.buffers()
					end,
				},
				{
					macro_text,
					cond = function()
						return vim.fn.reg_recording() ~= ""
					end,
					color = function()
						return { fg = c.red, gui = "bold" }
					end,
				},
				-- stylua: ignore
				{
          ---@diagnostic disable-next-line: undefined-field
					function() return require("noice").api.status.command.get() end,
          ---@diagnostic disable-next-line: undefined-field
					cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
					color = function() return { fg = Snacks.util.color("Statement") } end,
				},
			},
			lualine_y = {
				{
					function()
						if not package.loaded["copilot"] then
							return copilot_status_icons[""]
						end
						local s = copilot_status()
						return copilot_status_icons[s] or copilot_status_icons[""]
					end,
					cond = function()
						if not package.loaded["copilot"] then
							return false
						end
						local ok, clients = pcall(Utils.lsp.get_clients, { name = "copilot", bufnr = 0 })
						return ok and #clients > 0 and vim.o.columns >= W.medium
					end,
					color = function()
						local s = copilot_status()
						return { fg = copilot_colors[s] or copilot_colors[""] }
					end,
				},
				{
					get_lsps,
					cond = at_least(W.medium),
					color = function()
						return { fg = c.green, gui = "italic,bold" }
					end,
				},
			},
			lualine_z = {
				{ progress, padding = { left = 2, right = 1 } },
			},
		},
		extensions = {
			{
				sections = {
					lualine_a = {
						function()
							return " Lazygit"
						end,
					},
					lualine_b = { "branch" },
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = {},
				},
				filetypes = { "lazygit" },
			},
			{
				sections = {
					lualine_a = {
						function()
							local title = get_snacks()
							return title
						end,
					},
					lualine_b = {
						function()
							local _, meta = get_snacks()
							return meta
						end,
					},
				},
				filetypes = { "snacks_picker_input", "snacks_picker_list" },
			},
		},
	}

	return opts
end

Pack.when({ lazy_file = true }, function()
	local lualine_require = require("lualine_require")
	lualine_require.require = require

	local function setup()
		require("lualine").setup(build_opts(vim.g.custom_colors))
	end

	setup()
	macro_setup()

	vim.api.nvim_create_autocmd("User", {
		pattern = "CustomColorsUpdated",
		callback = setup,
	})
end)
