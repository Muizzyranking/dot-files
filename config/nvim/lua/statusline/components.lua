local M = {}

local utils = require("statusline.utils")

-- ===========================
-- show cmd
-- ===========================
function M.showcmd()
	if not Pack.has("noice.nvim") then
		return ""
	end
	---@diagnostic disable-next-line: undefined-field
	if package.loaded["noice"] and require("noice").api.status.command.has() then
		---@diagnostic disable-next-line: undefined-field
		local display = require("noice").api.status.command.get()
		return string.format("%%#StatuslineMacro# %s%%#StatuslineNC#", display)
	end
end

M.sep = "%#StatuslineSep# │ %#StatuslineNC#"

-- ===========================
-- mode
-- ===========================
---@return string
function M.mode()
	local raw = vim.api.nvim_get_mode().mode
	local icon = Utils.icons.modes[raw] or Utils.icons.ui.Target
	return utils.pill(icon)
end

-- ===========================
-- git branch (from gitsigns)
-- ===========================
function M.branch()
	local branch = vim.b.gitsigns_head or vim.g.gitsigns_head
	if not branch or branch == "" then
		return ""
	end
	local icon = (Utils and Utils.icons.git.branch) or ""
	return string.format("%%#StatuslineBranch#%s %s%%#StatuslineNC#", icon, branch)
end

-- ===========================
-- git diff (from gitsigns)
-- ===========================
M.diff = utils.cache({
	"BufEnter",
	"BufWritePost",
	{ event = "User", pattern = "GitSignsUpdate" },
}, function()
	local gs = vim.b.gitsigns_status_dict
	if not gs then
		return ""
	end
	local icons = (Utils and Utils.icons.git) or {}

	local parts = {}
	local added = gs.added or 0
	local changed = gs.changed or 0
	local removed = gs.removed or 0

	if added > 0 then
		table.insert(parts, string.format("%%#StatuslineDiffAdd#%s%d%%#StatuslineNC#", icons.added or "+", added))
	end
	if changed > 0 then
		table.insert(
			parts,
			string.format("%%#StatuslineDiffChange#%s%d%%#StatuslineNC#", icons.modified or "~", changed)
		)
	end
	if removed > 0 then
		table.insert(
			parts,
			string.format("%%#StatuslineDiffDelete#%s%d%%#StatuslineNC#", icons.removed or "-", removed)
		)
	end

	if #parts == 0 then
		return ""
	end
	return table.concat(parts, " ")
end, { per_buf = true })

-- ===========================
-- macro recording
-- ===========================
function M.macro()
	local reg = vim.fn.reg_recording()
	if reg == "" then
		return ""
	end
	return string.format("%%#StatuslineMacro# 󰑋 @%s%%#StatuslineNC#", reg)
end

-- ===========================
-- file name
-- ===========================

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

M.filename = function()
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
	local full = vim.api.nvim_buf_get_name(buf)
	local cols = vim.o.columns

	if full == "" then
		return "%#StatuslineFilename# 󰈚 [No Name]%#StatuslineNC#"
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
	local executable = full ~= "" and vim.fn.executable(full) == 1

	local hl
	if modified then
		hl = "StatuslineFilenameModified"
	elseif executable then
		hl = "StatuslineFilenameExec"
	else
		hl = "StatuslineFilename"
	end

	local mod_icon = modified and " ●" or ""
	local ro_icon = readonly and " 󰌾" or ""
	local ex_icon = executable and " 󰒃" or ""

	return string.format("%%#%s# %s %s%s%s%s%%#StatuslineNC#", hl, icon, display, mod_icon, ro_icon, ex_icon)
end

-- ===========================
-- buffers
-- ===========================
M.buffers = utils.cache({ "BufAdd", "BufDelete", "BufWipeout", "BufModifiedSet", "BufWritePost" }, function()
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
	local hl = dirty > 0 and "StatuslineBuffersDirty" or "StatuslineBuffers"
	local dirt = dirty > 0 and string.format(" ● %d", dirty) or ""

	return string.format("%%#%s# %s%d%s%%#StatuslineNC#", hl, icon, count, dirt)
end)

-- ===========================
-- diagnostics
-- ===========================
M.diagnostics = utils.cache({ "DiagnosticChanged", "BufEnter" }, function()
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
	local icons = (Utils and Utils.icons.diagnostics) or {}

	local items = {
		{ sev = vim.diagnostic.severity.ERROR, hl = "StatuslineDiagError", icon = icons.Error or " " },
		{ sev = vim.diagnostic.severity.WARN, hl = "StatuslineDiagWarn", icon = icons.Warn or " " },
		{ sev = vim.diagnostic.severity.INFO, hl = "StatuslineDiagInfo", icon = icons.Info or " " },
		{ sev = vim.diagnostic.severity.HINT, hl = "StatuslineDiagHint", icon = icons.Hint or "󰌶 " },
	}

	local parts = {}
	for _, item in ipairs(items) do
		local n = #vim.diagnostic.get(buf, { severity = item.sev })
		if n > 0 then
			table.insert(parts, string.format("%%#%s#%s%d%%#StatuslineNC#", item.hl, item.icon, n))
		end
	end

	if #parts == 0 then
		return ""
	end
	return table.concat(parts, " ")
end, { per_buf = true })

-- ===========================
-- LSP
-- ===========================
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

M.lsp = utils.cache({ "LspAttach", "LspDetach", "BufEnter" }, function()
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
	return string.format("%%#StatuslineLsp# 󰄭 %s%%#StatuslineNC#", table.concat(names, ", "))
end, { per_buf = true })

-- ===========================
-- copilot
-- ===========================
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

M.copilot = utils.cache({ "LspAttach", "LspDetach", "BufEnter" }, function()
	if not package.loaded["copilot"] then
		return ""
	end
	local ok, clients = pcall(vim.lsp.get_clients, { name = "copilot", bufnr = 0 })
	if not ok or #clients == 0 then
		return ""
	end
	local sok, status = pcall(function()
		return require("copilot.status").data
	end)
	local s = (sok and status and status.status) or "Normal"
	return string.format(
		"%%#%s# %s%%#StatuslineNC#",
		copilot_hls[s] or copilot_hls.Normal,
		copilot_icons[s] or copilot_icons.Normal
	)
end)

-- ===========================
-- search count (visible when searching)
-- ===========================
function M.searchcount()
	if vim.v.hlsearch == 0 then
		return ""
	end
	local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 50 })
	if not ok or not result or result.total == 0 then
		return ""
	end
	if result.incomplete == 1 then
		return "%#StatuslineSearch#  ?/?%#StatuslineNC#"
	end
	return string.format("%%#StatuslineSearch#  %d/%d%%#StatuslineNC#", result.current, result.total)
end

local bar_chars = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

function M.position()
	local line = vim.fn.line(".")
	local total = vim.fn.line("$")
	local ratio = line / math.max(total, 1)
	local bar = bar_chars[math.max(1, math.ceil(ratio * #bar_chars))]
	return string.format("%%#StatuslinePosition# %s%%#StatuslineNC#", bar)
end

return M
