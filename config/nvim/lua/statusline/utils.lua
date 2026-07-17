local M = {}

M.mode_key = {
	n = "Normal",
	no = "Normal",
	nov = "Normal",
	noV = "Normal",
	["no\22"] = "Normal",
	niI = "Normal",
	niR = "Normal",
	niV = "Normal",
	i = "Insert",
	ic = "Insert",
	ix = "Insert",
	v = "Visual",
	V = "Visual",
	[""] = "Visual",
	["\22"] = "Visual",
	vs = "Visual",
	Vs = "Visual",
	["\22s"] = "Visual",
	R = "Replace",
	Rc = "Replace",
	Rx = "Replace",
	Rv = "Replace",
	Rvc = "Replace",
	Rvx = "Replace",
	c = "Command",
	cv = "Command",
	ce = "Command",
	r = "Command",
	rm = "Command",
	["r?"] = "Command",
	["!"] = "Command",
	t = "Terminal",
	nt = "Terminal",
}

---@return integer
function M.stbuf()
	return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

---@param events (string|{event: string|string[], pattern: string|string[]})[]
---@param fn fun(): any
---@param opts { per_buf?: boolean }|nil
---@return fun(): any
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
			local buf = M.stbuf()
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

return M
