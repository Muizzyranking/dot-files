---@class PackUI
local M = {}

---@class PackUI.win
---@field buf integer
---@field win integer

local CFG = {
	width_ratio = 0.65,
	height_ratio = 0.70,
	border = "rounded",
	padding = 3,
	col = {
		status = 12,
		trigger = 20,
		load_ms = 9,
	},
	hl = {
		header = "Title",
		loaded = "DiagnosticOk",
		pending = "DiagnosticWarn",
		trigger = "Comment",
		load_ms = "Constant",
		key = "Special",
		separator = "NonText",
		updating = "DiagnosticInfo",
		updated = "DiagnosticOk",
		error = "DiagnosticError",
		cursor_line = "CursorLine",
		orphan = "DiagnosticError",
		orphan_header = "DiagnosticWarn",
	},
}

---@type PackUI.win?
local _ui = nil

---@type string[]
local _plugins = {}

---@type string[]
local _orphans = {}

local notify = Utils.notify.create({ title = "Pack UI" })

---@return integer width, integer height
local function win_dims()
	local W = math.floor(vim.o.columns * CFG.width_ratio)
	local H = math.floor(vim.o.lines * CFG.height_ratio)
	return W, H
end

---@param n integer
---@param max integer
---@return string
local function pad(s, n, max)
	s = tostring(s)
	if #s > max then
		s = s:sub(1, max - 1) .. "…"
	end
	return s .. string.rep(" ", n - #s)
end

---@param state Pack.state
---@return string
local function fmt_load_ms(state)
	if state.load_ms then
		return state.load_ms .. " ms"
	end
	return "—"
end

---@param W integer
---@return string header_line, string separator_line
local function make_header(W)
	local P = CFG.padding
	local used = P + CFG.col.status + CFG.col.trigger + CFG.col.load_ms
	local name_w = W - used
	local header = string.rep(" ", P)
		.. pad("Plugin", name_w, name_w)
		.. pad("Status", CFG.col.status, CFG.col.status)
		.. pad("Trigger", CFG.col.trigger, CFG.col.trigger)
		.. pad("Load ms", CFG.col.load_ms, CFG.col.load_ms)
	local sep = string.rep(" ", P) .. string.rep("─", W - P)
	return header, sep
end

---@param state Pack.state
---@param W integer
---@return string
local function make_row(state, W)
	local P = CFG.padding
	local used = P + CFG.col.status + CFG.col.trigger + CFG.col.load_ms
	local name_w = W - used
	local trigger = state.trigger or "—"
	return string.rep(" ", P)
		.. pad(state.name, name_w, name_w)
		.. pad(state.loaded and "● loaded" or "○ pending", CFG.col.status, CFG.col.status)
		.. pad(trigger, CFG.col.trigger, CFG.col.trigger)
		.. pad(fmt_load_ms(state), CFG.col.load_ms, CFG.col.load_ms)
end

---@param orphan string
---@param W integer
---@return string
local function make_orphan_row(orphan, W)
	local P = CFG.padding
	local used = P + CFG.col.status + CFG.col.trigger + CFG.col.load_ms
	local name_w = W - used
	return string.rep(" ", P)
		.. pad(orphan, name_w, name_w)
		.. pad("✗ orphan", CFG.col.status, CFG.col.status)
		.. pad("—", CFG.col.trigger, CFG.col.trigger)
		.. pad("—", CFG.col.load_ms, CFG.col.load_ms)
end

local function render()
	if not (_ui and vim.api.nvim_buf_is_valid(_ui.buf)) then
		return
	end

	local W = vim.api.nvim_win_get_width(_ui.win)
	local snapshot = Pack.snapshot()
	local plugins = snapshot.plugins
	local orphans = snapshot.orphans

	local names = vim.tbl_keys(plugins)
	table.sort(names, function(a, b)
		local sa, sb = plugins[a], plugins[b]
		if sa.loaded and sb.loaded then
			return (sa.loaded_at or 0) < (sb.loaded_at or 0)
		end
		if sa.loaded ~= sb.loaded then
			return sa.loaded
		end
		return a < b
	end)
	_plugins = names

	table.sort(orphans)
	_orphans = orphans

	local lines = {}
	local header, sep = make_header(W)

	table.insert(lines, "   Pack  " .. #names .. " plugins    U=update all   u=update  l=load  q=close")
	table.insert(lines, header)
	table.insert(lines, sep)

	for _, name in ipairs(names) do
		table.insert(lines, make_row(plugins[name], W))
	end

	if #orphans > 0 then
		table.insert(lines, "")
		table.insert(lines, string.rep(" ", CFG.padding) .. "─ Orphans (not registered, on disk) ─")
		table.insert(lines, sep)
		for _, orphan in ipairs(orphans) do
			table.insert(lines, make_orphan_row(orphan, W))
		end
	end

	vim.bo[_ui.buf].modifiable = true
	vim.api.nvim_buf_set_lines(_ui.buf, 0, -1, false, lines)
	vim.bo[_ui.buf].modifiable = false

	local ns = vim.api.nvim_create_namespace("pack_ui")
	vim.api.nvim_buf_clear_namespace(_ui.buf, ns, 0, -1)

	---@param row integer
	---@param col_start integer
	---@param col_end integer
	---@param group string
	local function hl(row, col_start, col_end, group)
		local line = vim.api.nvim_buf_get_lines(_ui.buf, row, row + 1, false)[1] or ""
		local line_len = #line
		if col_end == -1 then
			vim.api.nvim_buf_set_extmark(_ui.buf, ns, row, col_start, {
				hl_eol = true,
				hl_group = group,
			})
		else
			vim.api.nvim_buf_set_extmark(_ui.buf, ns, row, col_start, {
				end_col = math.min(col_end, line_len),
				end_row = row,
				hl_group = group,
			})
		end
	end

	hl(0, 0, -1, CFG.hl.header)
	hl(1, 0, -1, CFG.hl.header)
	hl(2, 0, -1, CFG.hl.separator)

	local P = CFG.padding
	local used = P + CFG.col.status + CFG.col.trigger + CFG.col.load_ms
	local name_w = W - used

	for i, name in ipairs(names) do
		local row = i + 2
		local state = plugins[name]
		local col0 = P + name_w

		local status_hl = state.loaded and CFG.hl.loaded or CFG.hl.pending
		hl(row, col0, col0 + CFG.col.status, status_hl)

		local col1 = col0 + CFG.col.status
		hl(row, col1, col1 + CFG.col.trigger, CFG.hl.trigger)

		local col2 = col1 + CFG.col.trigger
		if state.load_ms then
			hl(row, col2, -1, CFG.hl.load_ms)
		end
	end

	if #orphans > 0 then
		local orphan_header_row = 3 + #names + 1
		hl(orphan_header_row, 0, -1, CFG.hl.orphan_header)

		for i, _ in ipairs(orphans) do
			local row = orphan_header_row + 1 + i
			local col0 = P + name_w
			hl(row, col0, col0 + CFG.col.status, CFG.hl.orphan)
		end
	end
end

---@return string?
local function plugin_under_cursor()
	if not (_ui and vim.api.nvim_win_is_valid(_ui.win)) then
		return nil
	end
	local row = vim.api.nvim_win_get_cursor(_ui.win)[1]
	local idx = row - 3
	if idx < 1 or idx > #_plugins then
		return nil
	end
	return _plugins[idx]
end

local function setup_keymaps()
	if not (_ui and vim.api.nvim_buf_is_valid(_ui.buf)) then
		return
	end

	local keys = {
		q = function()
			M.close()
		end,
		l = function()
			local name = plugin_under_cursor()
			if not name then
				return
			end
			Pack.load(name)
			notify.info("[pack_ui] " .. name .. " is already loaded")
			render()
		end,
		u = function()
			local name = plugin_under_cursor()
			Pack.update({ name })
		end,
		r = function()
			render()
		end,
		U = function()
			Pack.update()
		end,
		X = function()
			if #_orphans == 0 then
				notify.info("[pack_ui] no orphans to clean")
				return
			end
			vim.ui.input({ prompt = "Clean all " .. #_orphans .. " orphan(s)? (y/N) " }, function(input)
				if input and input:lower() == "y" then
					notify.info("[pack_ui] cleaning all orphans…")
					local removed = Pack.clean()
					notify.info("[pack_ui] cleaned " .. #removed .. " orphan(s)")
					render()
				else
					notify.info("[pack_ui] aborted clean")
				end
			end)
		end,
	}

	for key, action in pairs(keys) do
		vim.keymap.set("n", key, action, { buffer = _ui.buf, nowait = true, silent = true })
	end
end

function M.open()
	if _ui and vim.api.nvim_win_is_valid(_ui.win) then
		vim.api.nvim_set_current_win(_ui.win)
		return
	end

	local W, H = win_dims()
	local row = math.floor((vim.o.lines - H) / 2)
	local col = math.floor((vim.o.columns - W) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].filetype = "pack_ui"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = W,
		height = H,
		border = CFG.border,
		style = "minimal",
		title = " 📦 Pack ",
		title_pos = "center",
		noautocmd = false,
	})

	vim.wo[win].cursorline = true
	vim.wo[win].wrap = false
	vim.wo[win].number = false
	vim.wo[win].signcolumn = "no"

	_ui = { buf = buf, win = win }

	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		once = true,
		callback = function()
			_ui = nil
			_plugins = {}
			_orphans = {}
		end,
	})

	setup_keymaps()
	render()

	vim.api.nvim_win_set_cursor(win, { 4, 0 })
end

function M.close()
	if _ui and vim.api.nvim_win_is_valid(_ui.win) then
		vim.api.nvim_win_close(_ui.win, true)
	end
	_ui = nil
	_plugins = {}
end

vim.api.nvim_create_user_command("PackUI", function()
	M.open()
end, { desc = "Open the Pack plugin manager UI" })

return M
