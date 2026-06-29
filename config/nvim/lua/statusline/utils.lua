---@class Statusline.Utils
local M = {}

M.NC = "StatuslineNC"

M.config = {
	default_fill_sep = "",
}

---@return string
function M.bg()
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "Normal", link = false })
	if ok and hl and hl.bg then
		return string.format("#%06x", hl.bg)
	end
	return "NONE"
end

local inline_cache = {}

---@param spec string|table|function
---@return string group_name
function M.resolve_hl(spec)
	if type(spec) == "function" then
		spec = spec()
	end
	if spec == nil then
		return M.NC
	end
	if type(spec) == "string" then
		return spec
	end

	local bg = spec.bg or M.bg()
	local key = table.concat({
		spec.fg or "",
		bg,
		tostring(spec.bold),
		tostring(spec.italic),
		tostring(spec.underline),
	}, "|")

	local cached = inline_cache[key]
	if cached then
		return cached
	end

	local name = "StatuslineInline" .. vim.fn.sha256(key):sub(1, 10)
	vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", spec, { bg = bg }))
	inline_cache[key] = name
	return name
end

function M.reset_inline_cache()
	inline_cache = {}
end

---@param hl Statusline.Hl
---@param content string|nil
---@return string
function M.wrap(hl, content)
	if content == nil or content == "" then
		return ""
	end
	local group = M.resolve_hl(hl)
	return string.format("%%#%s# %s %%#%s#", group, content, M.NC)
end

-- ============================================================
-- mode helpers (used for "fill" / dynamic-pill coloring)
-- ============================================================

local mode_key = {
	n = "Normal",
	no = "Normal",
	i = "Insert",
	ic = "Insert",
	v = "Visual",
	V = "Visual",
	s = "Visual",
	S = "Visual",
	[""] = "Visual",
	R = "Replace",
	Rv = "Replace",
	c = "Command",
	cv = "Command",
	r = "Command",
	["!"] = "Command",
	t = "Terminal",
	nt = "Terminal",
}

---@return string
function M.mode_key()
	local raw = vim.api.nvim_get_mode().mode
	return mode_key[raw] or "Normal"
end

---@return string
function M.mode_group()
	return "StatuslineMode" .. M.mode_key()
end

---@param hl Statusline.Hl       static color to use when dynamic == false
---@param dynamic boolean|nil    true -> use the live mode color instead of hl
---@return string
function M.fill_group(hl, dynamic)
	return dynamic and M.mode_group() or M.resolve_hl(hl)
end

---@param fill_group string  an already-resolved highlight group name
---@return string
function M.cap_for(fill_group)
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = fill_group, link = false })
	local fg = (ok and hl and hl.bg) and string.format("#%06x", hl.bg) or M.bg()
	return M.resolve_hl({ fg = fg, bg = M.bg() })
end

---@param char string|nil
---@param fill_group string
---@return string
function M.render_sep(char, fill_group)
	if not char or char == "" then
		return ""
	end
	local fade_group = M.cap_for(fill_group)
	return string.format("%%#%s#%s%%#%s#", fade_group, char, M.NC)
end

---@param events (string|Statusline.Utils.CacheEvent)[]
---@param fn fun(): string
---@param opts? Statusline.Utils.CacheOpts
---@return fun(): string
function M.cache(events, fn, opts)
	opts = opts or {}
	local per_buf = opts.per_buf or false
	---@type table<integer, string>|{ value: string|nil }
	local store = per_buf and {} or { value = nil }
	local group = vim.api.nvim_create_augroup("statusline.cache." .. tostring(fn), { clear = true })

	local function invalidate(buf)
		if per_buf then
			if buf then
				store[buf] = nil
			else
				store = {}
			end
		else
			store.value = nil
		end
		vim.schedule(function()
			vim.cmd.redrawstatus()
		end)
	end

	for _, ev in ipairs(events) do
		if type(ev) == "string" then
			vim.api.nvim_create_autocmd(ev, {
				group = group,
				callback = function(e)
					invalidate(e.buf)
				end,
			})
		elseif type(ev) == "table" then
			vim.api.nvim_create_autocmd(ev.event, {
				group = group,
				pattern = ev.pattern,
				callback = function(e)
					invalidate(e.buf)
				end,
			})
		end
	end

	return function()
		if per_buf then
			local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
			if store[buf] == nil then
				store[buf] = fn()
			end
			return store[buf]
		else
			if store.value == nil then
				store.value = fn()
			end
			return store.value
		end
	end
end

---@return integer
function M.stbuf()
	return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

return M
