---@class Statusline.Components
local M = {}

local utils = require("statusline.utils")

---@param opts Statusline.ComponentOpts
function M.new(opts)
	local render = opts.render
	if opts.cache then
		render = utils.cache(opts.cache.events, render, { per_buf = opts.cache.per_buf })
	end
	return {
		render = render,
		hl = opts.hl,
		fill = opts.fill,
		sep = opts.sep,
		raw = opts.raw,
	}
end

---Quick helper for plain filetype "labels" (Lazygit / Oil / Mason...).
---Defaults to the dynamic mode color, like the old utils.pill did.
---@param text string
---@param opts? Statusline.LabelOpts
---@return Statusline.Component
function M.label(text, opts)
	opts = opts or {}
	return M.new({
		render = function()
			return text
		end,
		hl = opts.hl or "StatuslineModeNormal",
		fill = opts.fill == nil or opts.fill,
	})
end

-- ============================================================
-- mode
-- ============================================================
M.mode = M.new({
	render = function()
		local raw = vim.api.nvim_get_mode().mode
		return Utils.icons.modes[raw] or Utils.icons.ui.Target
	end,
	fill = true,
})

-- ============================================================
-- show cmd (noice)
-- ============================================================
M.showcmd = M.new({
	hl = "StatuslineMacro",
	render = function()
		if not Pack.has("noice.nvim") then
			return ""
		end
		---@diagnostic disable-next-line: undefined-field
		if package.loaded["noice"] and require("noice").api.status.command.has() then
			---@diagnostic disable-next-line: undefined-field
			return require("noice").api.status.command.get()
		end
		return ""
	end,
})

-- ============================================================
-- git branch (gitsigns)
-- ============================================================
M.branch = M.new({
	hl = "StatuslineBranch",
	render = function()
		local branch = vim.b.gitsigns_head or vim.g.gitsigns_head
		if not branch or branch == "" then
			return ""
		end
		local icon = (Utils and Utils.icons.git.branch) or ""
		return string.format("%s %s", icon, branch)
	end,
})

-- ============================================================
-- git diff (gitsigns)
-- ============================================================
M.diff = M.new({
	raw = true,
	cache = {
		events = { "BufEnter", "BufWritePost", { event = "User", pattern = "GitSignsUpdate" } },
		per_buf = true,
	},
	render = function()
		local gs = vim.b.gitsigns_status_dict
		if not gs then
			return ""
		end
		local icons = (Utils and Utils.icons.git) or {}

		local parts = {}
		local added, changed, removed = gs.added or 0, gs.changed or 0, gs.removed or 0

		if added > 0 then
			table.insert(parts, utils.wrap("StatuslineDiffAdd", string.format("%s%d", icons.added or "+", added)))
		end
		if changed > 0 then
			table.insert(
				parts,
				utils.wrap("StatuslineDiffChange", string.format("%s%d", icons.modified or "~", changed))
			)
		end
		if removed > 0 then
			table.insert(
				parts,
				utils.wrap("StatuslineDiffDelete", string.format("%s%d", icons.removed or "-", removed))
			)
		end

		return table.concat(parts)
	end,
})

-- ============================================================
-- macro recording
-- ============================================================
local rec_timer, rec_blink = nil, false

M.macro = M.new({
	raw = true,
	render = function()
		local reg = vim.fn.reg_recording()
		if reg == "" then
			return ""
		end
		local dot_hl = rec_blink and "StatuslineRecording" or "StatuslineRecordingDim"
		local dot_icon = rec_blink and "●" or "○"
		return utils.wrap(dot_hl, dot_icon) .. utils.wrap("StatuslineMacro", "@" .. reg)
	end,
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
M.root = M.new({
	hl = "StatuslineRoot",
	render = function()
		local root = Utils.root.get()
		if not root then
			return ""
		end
		return string.format("󱉭 %s", vim.fn.fnamemodify(root, ":t"))
	end,
	sep = { left = "", right = "" },
	-- sep = { left = "", right = "" },
	fill = true,
})

-- ============================================================
-- file path
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

local function filepath_hl()
	local buf = utils.stbuf()
	local full = vim.api.nvim_buf_get_name(buf)
	if vim.bo[buf].modified then
		return "StatuslineFilenameModified"
	elseif full ~= "" and vim.fn.executable(full) == 1 then
		return "StatuslineFilenameExec"
	end
	return "StatuslineFilename"
end

M.filepath = M.new({
	hl = filepath_hl,
	fill = false,
	render = function()
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
	end,
})

-- ============================================================
-- buffers
-- ============================================================
M.buffers = M.new({
	cache = { events = { "BufAdd", "BufDelete", "BufWipeout", "BufModifiedSet", "BufWritePost" } },
	hl = function()
		for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
			if vim.bo[buf.bufnr].modified then
				return "StatuslineBuffersDirty"
			end
		end
		return "StatuslineBuffers"
	end,
	render = function()
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
	end,
})

-- ============================================================
-- diagnostics
-- ============================================================
M.diagnostics = M.new({
	raw = true,
	cache = { events = { "DiagnosticChanged", "BufEnter" }, per_buf = true },
	render = function()
		local buf = utils.stbuf()
		local icons = (Utils and Utils.icons.diagnostics) or {}

		local items = {
			{ sev = vim.diagnostic.severity.ERROR, hl = "StatuslineDiagError", icon = icons.Error },
			{ sev = vim.diagnostic.severity.WARN, hl = "StatuslineDiagWarn", icon = icons.Warn },
			{ sev = vim.diagnostic.severity.INFO, hl = "StatuslineDiagInfo", icon = icons.Info },
			{ sev = vim.diagnostic.severity.HINT, hl = "StatuslineDiagHint", icon = icons.Hint },
		}

		local parts = {}
		for _, item in ipairs(items) do
			local n = #vim.diagnostic.get(buf, { severity = item.sev })
			if n > 0 then
				table.insert(parts, utils.wrap(item.hl, string.format("%s%d", item.icon, n)))
			end
		end

		return table.concat(parts, " ")
	end,
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

M.lsp = M.new({
	hl = "StatuslineLsp",
	cache = { events = { "LspAttach", "LspDetach", "BufEnter" }, per_buf = true },
	render = function()
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
		return string.format("󰄭 %s", table.concat(names, ", "))
	end,
})

-- ============================================================
-- copilot
-- ============================================================
local copilot_icons = {
	Normal = Utils.icons.kinds.Copilot,
	Warning = "",
	InProgress = "",
	Error = "",
}
local copilot_hls = {
	Normal = "StatuslineCopilotOk",
	Warning = "StatuslineCopilotWarn",
	InProgress = "StatuslineCopilotWarn",
	Error = "StatuslineCopilotError",
}

local function copilot_status()
	local sok, status = pcall(function()
		return require("copilot.status").data
	end)
	return (sok and status and status.status) or "Normal"
end

M.copilot = M.new({
	hl = function()
		return copilot_hls[copilot_status()] or copilot_hls.Normal
	end,
	cache = { events = { "LspAttach", "LspDetach", "BufEnter" } },
	render = function()
		if not package.loaded["copilot"] then
			return ""
		end
		local ok, clients = pcall(vim.lsp.get_clients, { name = "copilot", bufnr = 0 })
		if not ok or #clients == 0 then
			return ""
		end
		return copilot_icons[copilot_status()] or copilot_icons.Normal
	end,
})

-- ============================================================
-- search count
-- ============================================================
M.searchcount = M.new({
	hl = "StatuslineSearch",
	render = function()
		if vim.v.hlsearch == 0 then
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
})

-- ============================================================
-- position bar
-- ============================================================
local bar_chars = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

M.position = M.new({
	hl = "StatuslinePosition",
	render = function()
		local line = vim.fn.line(".")
		local total = vim.fn.line("$")
		local ratio = line / math.max(total, 1)
		return bar_chars[math.max(1, math.ceil(ratio * #bar_chars))]
	end,
	fill = true,
})

function M.setup()
	M.macro_setup()
end

return M
