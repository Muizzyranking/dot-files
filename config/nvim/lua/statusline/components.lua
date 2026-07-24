local M = {}

local utils = require("statusline.utils")
local Component = require("statusline.component")

---@param text string
---@param opts? { hl?: string|table|function, sep?: table, cond?: fun():boolean }
---@return Statusline.Component
function M.label(text, opts)
	opts = opts or {}
	return Component.new({
		value = function()
			return text
		end,
		hl = opts.hl or { dynamic = true },
		sep = opts.sep or { left = "", right = "" },
		cond = opts.cond,
	})
end

M.new = Component.new

-- ============================================================
-- mode
-- ============================================================
M.mode = Component.new({
	value = function()
		local raw = vim.api.nvim_get_mode().mode
		return Utils.icons.modes[raw] or Utils.icons.ui.Target
	end,
	hl = { dynamic = true },
	sep = { left = "", right = "" },
})

-- ============================================================
-- show cmd (noice)
-- ============================================================
M.showcmd = Component.new({
	cond = function()
		return Pack.has("noice.nvim")
	end,
	value = function()
		---@diagnostic disable-next-line: undefined-field
		if package.loaded["noice"] and require("noice").api.status.command.has() then
			---@diagnostic disable-next-line: undefined-field
			return require("noice").api.status.command.get()
		end
		return ""
	end,
	hl = "#f7768e",
})

-- ============================================================
-- git branch (gitsigns)
-- ============================================================
M.branch = Component.new({
	cond = function()
		return (vim.b.gitsigns_head or vim.g.gitsigns_head) ~= nil
	end,
	value = function()
		local branch = vim.b.gitsigns_head or vim.g.gitsigns_head
		if not branch or branch == "" then
			return ""
		end
		local icon = (Utils and Utils.icons.git.branch) or ""
		return string.format("%s %s", icon, branch)
	end,
	hl = { italic = true },
})

-- ============================================================
-- git diff (gitsigns)
-- One component, 3 segments -- each fragment gets its own color, and they
-- render touching each other (spacing = 0, the default) like the original.
-- ============================================================
local git_status = utils.cache({
	"BufEnter",
	"BufWritePost",
	{ event = "User", pattern = "GitSignsUpdate" },
}, function()
	return vim.b.gitsigns_status_dict
end, { per_buf = true })

M.diff = Component.new({
	value = function()
		local gs = git_status()
		if not gs then
			return {}
		end
		local icons = (Utils and Utils.icons.git) or {}
		local added, changed, removed = gs.added or 0, gs.changed or 0, gs.removed or 0

		local segments = {}
		if added > 0 then
			table.insert(segments, { text = string.format("%s%d", icons.added or "+", added), hl = "green" })
		end
		if changed > 0 then
			table.insert(segments, { text = string.format("%s%d", icons.modified or "~", changed), hl = "orange" })
		end
		if removed > 0 then
			table.insert(segments, { text = string.format("%s%d", icons.removed or "-", removed), hl = "red" })
		end
		if #segments == 0 then
			return {}
		end
		table.insert(segments, { text = "│", hl = "fg_dimmer" })
		return segments
	end,
	spacing = 1,
})

-- ============================================================
-- macro recording
-- Single static hl -- only the dot glyph blinks, not the color.
-- ============================================================
local rec_timer, rec_blink = nil, false

M.macro = Component.new({
	value = function()
		local reg = vim.fn.reg_recording()
		if reg == "" then
			return ""
		end
		local dot = rec_blink and "●" or "○"
		return string.format("%s @%s", dot, reg)
	end,
	hl = "#f7768e",
})

function M.macro_setup()
	local function set_timer()
		local rec = vim.fn.reg_recording() ~= ""
		if rec and not rec_timer then
			rec_blink = true
			rec_timer = vim.loop.new_timer()
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

-- ============================================================
-- root
-- ============================================================
M.root = Component.new({
	value = utils.cache({ "DirChanged", "BufEnter" }, function()
		local root = Utils.root.get()
		if not root then
			return ""
		end
		return string.format("󱉭 %s", vim.fn.fnamemodify(root, ":t"))
	end),
	hl = { dynamic = true },
	sep = { left = "", right = "" },
})

-- ============================================================
-- file path
-- Color depends on buffer state (modified / executable / plain) -- hl as
-- a function handles this in one component.
-- ============================================================
local function truncate_path(rel, max)
	if #rel <= max then
		return rel
	end
	local parts = vim.split(rel, "/", { plain = true })
	if #parts <= 1 then
		return "…" .. rel:sub(-(max - 1))
	end
	local name = parts[#parts]
	local short = {}
	for i = 1, #parts - 1 do
		table.insert(short, parts[i]:sub(1, 1))
	end
	return table.concat(short, "/") .. "/" .. name
end

local function filepath_text()
	local buf = utils.stbuf()
	local full = vim.api.nvim_buf_get_name(buf)
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

	local modified = vim.bo[buf].modified
	local readonly = vim.bo[buf].readonly or not vim.bo[buf].modifiable
	local executable = vim.fn.executable(full) == 1

	local mod_icon = modified and " ●" or ""
	local ro_icon = readonly and " 󰌾" or ""
	local ex_icon = executable and " 󰒃" or ""

	return string.format("%s %s%s%s%s", icon, display, mod_icon, ro_icon, ex_icon)
end

local function filepath_state()
	local buf = utils.stbuf()
	local full = vim.api.nvim_buf_get_name(buf)
	if vim.bo[buf].modified then
		return "modified"
	elseif full ~= "" and vim.fn.executable(full) == 1 then
		return "exec"
	end
	return "normal"
end

M.filepath = Component.new({
	value = filepath_text,
	hl = function()
		local state = filepath_state()
		if state == "modified" then
			return { fg = "orange" }
		elseif state == "exec" then
			return { fg = "green" }
		end
		return { fg = "fg" }
	end,
})

-- ============================================================
-- buffers
-- ============================================================
local function any_buffer_dirty()
	for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
		if vim.bo[buf.bufnr].modified then
			return true
		end
	end
	return false
end

local buffers_text = utils.cache({ "BufAdd", "BufDelete", "BufWipeout", "BufModifiedSet", "BufWritePost" }, function()
	local listed = vim.fn.getbufinfo({ buflisted = 1 })
	local count = #listed
	if count == 0 then
		return ""
	end

	local dirty = 0
	for _, buf in ipairs(listed) do
		if vim.bo[buf.bufnr].modified then
			dirty = dirty + 1
		end
	end

	local icon = (Utils and Utils.icons.ui and Utils.icons.ui.buffer) or "󰓩"
	local dirt = dirty > 0 and string.format(" ● %d", dirty) or ""
	return string.format("%s%d%s", icon, count, dirt)
end)

M.buffers = Component.new({
	value = function()
		return {
			{ text = buffers_text() },
			{ text = "│", hl = "fg_dimmer" },
		}
	end,
	hl = function()
		return { fg = any_buffer_dirty() and "orange" or "fg_dim" }
	end,
	spacing = 1,
})

-- ============================================================
-- diagnostics
-- One component, up to 4 segments, joined with a single space -- matching
-- how the old combined "E3 W2 I1 H1" text looked.
-- ============================================================
local diagnostic_counts = utils.cache({ "DiagnosticChanged", "BufEnter" }, function()
	local buf = utils.stbuf()
	return {
		error = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR }),
		warn = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.WARN }),
		info = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.INFO }),
		hint = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.HINT }),
	}
end, { per_buf = true })

local diag_icons = (Utils and Utils.icons and Utils.icons.diagnostics) or {}

M.diagnostics = Component.new({
	value = function()
		local counts = diagnostic_counts()
		local segments = {}
		if counts.error > 0 then
			table.insert(segments, { text = string.format("%s%d", diag_icons.Error or "E", counts.error), hl = "red" })
		end
		if counts.warn > 0 then
			table.insert(segments, { text = string.format("%s%d", diag_icons.Warn or "W", counts.warn), hl = "orange" })
		end
		if counts.info > 0 then
			-- Not one of the 6 named hues -- pass the actual highlight group straight through.
			table.insert(
				segments,
				{ text = string.format("%s%d", diag_icons.Info or "I", counts.info), hl = "DiagnosticInfo" }
			)
		end
		if counts.hint > 0 then
			table.insert(
				segments,
				{ text = string.format("%s%d", diag_icons.Hint or "H", counts.hint), hl = "DiagnosticHint" }
			)
		end
		if #segments == 0 then
			return {}
		end
		table.insert(segments, { text = "│", hl = "fg_dimmer" })
		return segments
	end,
	spacing = 1, -- old diagnostics joined severities with a space
})

-- ============================================================
-- LSP
-- ============================================================
local function truncate_lsp(name)
	if #name <= 10 then
		return name
	end
	if name:find("_") then
		name = name:match("([^_]+)") or name
	end
	if #name > 10 then
		name = name:sub(1, 10) .. "…"
	end
	return name
end

M.lsp = Component.new({
	value = utils.cache({ "LspAttach", "LspDetach", "BufEnter" }, function()
		if vim.o.columns <= 100 then
			return ""
		end
		local clients = vim.lsp.get_clients({ bufnr = 0 })
		local names = {}
		for _, c in ipairs(clients) do
			if c.name ~= "conform" and c.name ~= "copilot" then
				table.insert(names, #clients > 2 and truncate_lsp(c.name) or c.name)
			end
		end
		if #names == 0 then
			return ""
		end
		return {
			{ text = string.format("󰄭 %s", table.concat(names, ", ")) },
			{ text = " │", hl = "fg_dimmer" },
		}
	end, { per_buf = true }),
	hl = "green",
})

-- ============================================================
-- copilot
-- Only one status is ever active at a time -- hl as a function handles
-- this in one component.
-- ============================================================
local copilot_icons = {
	Normal = Utils.icons.kinds.Copilot,
	Warning = "",
	InProgress = "",
	Error = "",
}

local function copilot_status()
	local sok, status = pcall(function()
		return require("copilot.status").data
	end)
	return (sok and status and status.status) or "Normal"
end

local function copilot_active()
	if not package.loaded["copilot"] then
		return false
	end
	local ok, clients = pcall(vim.lsp.get_clients, { name = "copilot", bufnr = 0 })
	return ok and #clients > 0
end

local copilot_icon = utils.cache({ "LspAttach", "LspDetach", "BufEnter" }, function()
	if not copilot_active() then
		return ""
	end
	return {
		{ text = copilot_icons[copilot_status()] or copilot_icons.Normal },
		{ text = " │", hl = "fg_dimmer" },
	}
end)

M.copilot = Component.new({
	value = copilot_icon,
	hl = function()
		local s = copilot_status()
		if s == "Error" then
			return { fg = "red" }
		elseif s == "Warning" or s == "InProgress" then
			return { fg = "orange" }
		end
		return { fg = "green" }
	end,
})

-- ============================================================
-- search count
-- ============================================================
M.searchcount = Component.new({
	value = function()
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
	end,
	hl = "cyan",
})

-- ============================================================
-- position bar
-- ============================================================
local bar_chars = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

M.position = Component.new({
	value = function()
		local line = vim.fn.line(".")
		local total = vim.fn.line("$")
		local ratio = line / math.max(total, 1)
		return bar_chars[math.max(1, math.ceil(ratio * #bar_chars))]
	end,
	hl = { dynamic = true },
})

function M.setup()
	M.macro_setup()
end

return M
