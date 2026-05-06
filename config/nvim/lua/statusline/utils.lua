---@class Statusline.Utils
local M = {}
local SLANT = ""

---@class Statusline.Utils.CacheOpts
---@field per_buf? boolean

---@class Statusline.Utils.CacheEvent
---@field event string
---@field pattern? string

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

M.PILL_TAG = "\x01PILL\x01"

local mode_key = {
	n = "Normal",
	no = "Normal",
	i = "Insert",
	ic = "Insert",
	v = "Visual",
	V = "Visual",
	s = "Visual",
	S = "Visual",
	R = "Replace",
	Rv = "Replace",
	c = "Command",
	cv = "Command",
	r = "Command",
	["!"] = "Command",
	t = "Terminal",
	nt = "Terminal",
}

mode_key[""] = "Visual"

---@param content string
function M.pill(content)
	local raw = vim.api.nvim_get_mode().mode
	local key = mode_key[raw] or "Normal"
	local rendered =
		string.format("%%#StatuslineMode%s# %s %%#StatuslineSlant%s#%s %%#StatuslineNC#", key, content, key, SLANT)
	return M.PILL_TAG .. rendered
end

---@return integer
function M.stbuf()
	return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

return M
