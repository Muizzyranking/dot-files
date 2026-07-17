---@class Pack
local M = {}

---@class Pack.when.spec
---@field event string|string[]?
---@field pattern string|string[]?
---@field ft string|string[]?
---@field cmd string|string[]?
---@field keys KeymapOpts[]?
---@field lazy_file boolean?
---@field defer boolean?

---@class Pack.AddSpec
---@field [1] string
---@field name string?
---@field version string?

---@class Pack.ChangeParams
---@field name string
---@field path string
---@field kind string
---@field active boolean

---@alias Pack.ChangeKind
---| "install"
---| "update"
---| "delete"

local notify = Utils.notify.create({ title = "Pack" })

---@type table<string, boolean>
M.specs = {}
---@type table<string, boolean>
M.loaded = {}

---@param name? string
local function mark_loaded(name)
	if not name then
		return
	end
	M.loaded[name] = true
	vim.api.nvim_exec_autocmds("User", { pattern = "PackLoad:" .. name })
end

local function resolve_src(src)
	if src:match("^https?://") then
		return src
	end
	return "https://github.com/" .. src
end

local function packadd(spec, opts)
	opts = opts or {}
	opts.confirm = false
	vim.pack.add({ spec }, opts)
end

---@param src string
---@return string
local function name_from_src(src)
	return src:match("/([^/]+)$"):gsub("%.git$", "")
end

---@param msg string
---@param fn fun()
local function safe(msg, fn)
	local ok, err = pcall(fn)
	if not ok then
		notify.error(string.format("[pack] %s: %s", msg, err))
	end
end

---@param event string|string[]
---@param pattern string|string[]?
---@param trigger fun()
local function watch_event(event, pattern, trigger)
	vim.api.nvim_create_autocmd(event, {
		pattern = pattern,
		once = true,
		callback = function()
			safe("event()", trigger)
		end,
	})
end

---@param keys KeymapOpts[]
---@param trigger fun()
local function watch_keys(keys, trigger)
	local mappings = {}
	for _, k in ipairs(keys) do
		table.insert(mappings, {
			k[1],
			function()
				trigger()
				if type(k[2]) == "function" then
					if k.expr then
						return k[2]()
					end
					k[2]()
				else
					vim.cmd(k[2])
				end
			end,
			desc = k.desc or "",
			mode = k.mode or "n",
			buffer = k.buffer,
			silent = true,
			expr = k.expr,
			icon = k.icon,
			conds = k.conds,
			has = k.has,
		})
	end
	Utils.map.set(mappings)
end

---@param trigger fun()
local function watch_lazy_file(trigger)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePre" }, {
		desc = "[pack] lazy_file trigger",
		callback = function(ev)
			if vim.bo[ev.buf].buftype ~= "" or vim.api.nvim_buf_get_name(ev.buf) == "" then
				return
			end
			trigger()
		end,
	})
end

---@param trigger fun()
local function watch_defer(trigger)
	vim.api.nvim_create_autocmd("UIEnter", {
		once = true,
		desc = "[pack] defer trigger",
		callback = function()
			vim.schedule(trigger)
		end,
	})
end

---@param spec Pack.when.spec
---@param fn fun()
---@param name string?
function M.when(spec, fn, name)
	if name then
		assert(M.has(name), string.format("[pack] when: '%s' is not registered", name))
	end
	local done = false
	local function trigger()
		if done then
			return
		end
		done = true
		if name then
			mark_loaded(name)
		end
		safe("when()", fn)
	end

	if spec.event then
		watch_event(spec.event, spec.pattern, trigger)
	end
	if spec.ft then
		watch_event("FileType", spec.ft, trigger)
	end
	if spec.keys then
		watch_keys(spec.keys, trigger)
	end
	if spec.lazy_file then
		watch_lazy_file(trigger)
	end
	if spec.defer then
		watch_defer(trigger)
	end
end

function M.lazy_file(fn, name)
	if name then
		assert(M.has(name), string.format("[pack] lazyfile: '%s' is not registered", name))
		mark_loaded(name)
	end
	watch_lazy_file(fn)
end

---@param fn fun()
---@param name string?
function M.now(fn, name)
	if name then
		assert(M.has(name), string.format("[pack] now: '%s' is not registered", name))
		mark_loaded(name)
	end
	safe("now()", fn)
end

---@param fn fun()
function M.defer(fn, name)
	if name then
		assert(M.has(name), string.format("[pack] now: '%s' is not registered", name))
		mark_loaded(name)
	end
	watch_defer(fn)
end

---@param name string
---@return boolean
function M.has(name)
	if M.specs[name] then
		return true
	end
	return false
end

---@param name string
---@param fn fun()
function M.on_load(name, fn)
	if M.loaded[name] then
		safe(string.format("on_load('%s')", name), fn)
		return
	end
	vim.api.nvim_create_autocmd("User", {
		pattern = "PackLoad:" .. name,
		once = true,
		desc = string.format("[pack] on_load for '%s'", name),
		callback = function()
			safe(string.format("on_load('%s')", name), fn)
		end,
	})
end

---@param spec string|Pack.AddSpec|(string|Pack.AddSpec)[]
function M.add(spec)
	assert(type(spec) == "string" or type(spec) == "table", "[pack] add: expected a string or table")

	if type(spec) == "string" or (type(spec[1]) == "string" and spec[2] == nil) then
		spec = { spec }
	end

	for _, s in ipairs(spec) do
		local item = type(s) == "string" and { s } or s
		assert(
			type(item) == "table" and type(item[1]) == "string",
			"[pack] add: each entry must be a string or a table with a string field"
		)

		local src = resolve_src(item[1])
		local name = item.name or name_from_src(src)
		M.specs[name] = true

		local pack_spec = { src = src }
		if item.name then
			pack_spec.name = item.name
		end
		if item.version then
			pack_spec.version = item.version
		end
		packadd(pack_spec)
	end
end

function M.is_loaded(name)
	return M.loaded[name] or false
end

---@param name string
---@param fn fun(params: Pack.ChangeParams)
---@param kind Pack.ChangeKind|Pack.ChangeKind[]?
function M.on_changed(name, fn, kind)
	kind = type(kind) == "string" and { kind } or kind or { "install", "update" }
	local allowed = {}
	---@diagnostic disable-next-line: param-type-mismatch
	for _, k in ipairs(kind) do
		allowed[k] = true
	end
	vim.api.nvim_create_autocmd("PackChanged", {
		desc = string.format("[pack] on_changed for '%s'", name),
		callback = function(ev)
			if ev.data.spec.name ~= name then
				return
			end
			if not allowed[ev.data.kind] then
				return
			end

			local params = {
				name = ev.data.spec.name,
				path = vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. ev.data.spec.name,
				kind = ev.data.kind,
				active = ev.data.active,
			}

			if not ev.data.active then
				vim.cmd.packadd(name)
			end
			safe(string.format("on_changed('%s')", name), function()
				fn(params)
			end)
		end,
	})
end

return M
