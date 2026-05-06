---@class Pack
local M = {}

---@class Pack.state
---@field src string
---@field name string
---@field loaded boolean
---@field registered_at number
---@field loaded_at number?
---@field trigger string?
---@field load_ms number?

---@class Pack.Spec
---@field src string
---@field name string?
---@field load boolean?
---@field version string?
---@field config fun()?
---@field fn fun()?

local notify = Utils.notify.create({ title = "Pack" })

---@type table<string, Pack.state>
local _state = {}

local function resolve_src(src)
	if src:match("^https?://") then
		return src
	end
	return "https://github.com/" .. src
end

local function name_from_src(src)
	return src:match("/([^/]+)$"):gsub("%.git$", "")
end

---@param name string
---@param trigger string
local function mark_loaded(name, trigger)
	if _state[name] then
		_state[name].loaded = true
		_state[name].loaded_at = vim.uv.now()
		_state[name].trigger = trigger
	end
	vim.api.nvim_exec_autocmds("User", { pattern = "PackLoad:" .. name })
end

---@param name string
---@param trigger string
local function do_load(name, trigger)
	if M.is_loaded(name) then
		return
	end
	local t = vim.uv.now()
	vim.cmd.packadd(name)
	mark_loaded(name, trigger)
	if _state[name] then
		_state[name].load_ms = vim.uv.now() - t
	end
end

---@param msg string
---@param fn fun()
local function protected(msg, fn)
	local ok, err = pcall(fn)
	if not ok then
		notify.error(string.format("[pack] %s: %s", msg, err))
	end
end

---@param spec string|vim.pack.Spec
---@param opts? { confirm?: boolean, load?: fun() }
local function packadd(spec, opts)
	opts = opts or {}
	opts.confirm = false
	vim.pack.add({ spec }, opts)
end

---@param spec Pack.Spec|Pack.Spec[]
function M.add(spec)
	assert(type(spec) == "table", "[pack] add: expected a table or array of tables")

	if spec.src then
		spec = { spec }
	end

	for _, s in ipairs(spec) do
		assert(type(s) == "table" and s.src, "[pack] add: each spec must be a table with a 'src' field")
		local src = resolve_src(s.src)
		local name = s.name or name_from_src(src)

		_state[name] = {
			src = src,
			name = name,
			loaded = false,
			registered_at = vim.uv.now(),
			loaded_at = nil,
			trigger = nil,
		}

		local pack_spec = { src = src, name = name }
		if s.version then
			pack_spec.version = s.version
		end

		local fn = s.config or s.fn
		local load = s.load
		if load and fn == nil then
			fn = function() end
		end

		if fn then
			packadd(pack_spec)
			mark_loaded(name, "immediate")
			protected("add(" .. name .. ")", fn)
		else
			packadd(pack_spec, { load = function() end })
		end
	end
end

---@param name string
---@param ctx string
function M.deps(name, ctx)
	if not M.has(name) then
		error(string.format("[pack] dependency '%s' required by %s is not present", name, ctx))
	end
	if not M.is_loaded(name) then
		protected("deps(" .. name .. ")", function()
			do_load(name, "deps: " .. ctx)
		end)
	end
end

---@param name string
function M.load(name)
	assert(_state[name], string.format("[pack] load: '%s' is not registered", name))
	do_load(name, "manual")
end

---@param fn fun()
---@param name string?
function M.now(fn, name)
	if name then
		M.load(name)
	end
	protected(string.format("now('%s')", name or "anon"), fn)
end

---@param name string
---@param fn   fun()
function M.on_load(name, fn)
	if M.is_loaded(name) then
		protected("on_load(" .. name .. ")", fn)
		return
	end
	vim.api.nvim_create_autocmd("User", {
		pattern = "PackLoad:" .. name,
		once = true,
		desc = string.format("[pack] on_load for '%s'", name),
		callback = function()
			protected("on_load(" .. name .. ")", fn)
		end,
	})
end

---@param keys KeymapOpts[]
---@param fn fun()
---@param name string|nil
function M.on_key(keys, fn, name)
	if name then
		assert(_state[name], string.format("[pack] on_key: '%s' is not registered", name))
	end
	local loaded = false

	---@param action fun()|string
	local function make_action(action, is_expr)
		return function()
			if not loaded then
				if name then
					do_load(name, "key")
				end
				protected("on_key(" .. (name or "anon") .. ")", fn)
				loaded = true
			end

			if type(action) == "function" then
				if is_expr then
					return action()
				end
				action()
			else
				vim.cmd(action)
			end
		end
	end

	local mappings = {}
	for _, k in ipairs(keys) do
		local modes = k.mode or "n"
		table.insert(mappings, {
			k[1],
			make_action(k[2], k.expr),
			desc = k.desc or "",
			mode = modes,
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

---Lazy-load on filetype(s).
---@param ft string|string[]
---@param fn fun()
---@param name string?
function M.on_ft(ft, fn, name)
	if name then
		assert(_state[name], string.format("[pack] on_ft: '%s' is not registered", name))
	end
	vim.api.nvim_create_autocmd("FileType", {
		pattern = type(ft) == "table" and ft or { ft },
		once = true,
		desc = string.format("[pack] on_ft for '%s'", name or "anon"),
		callback = function()
			if name then
				do_load(name, "ft")
			end
			protected("on_ft(" .. (name or "anon") .. ")", fn)
		end,
	})
end

---@param cmds string|string[]
---@param fn fun()
---@param name string|nil
function M.on_cmd(cmds, fn, name)
	if name then
		assert(_state[name], string.format("[pack] on_cmd: '%s' is not registered", name))
	end
	if type(cmds) == "string" then
		cmds = { cmds }
	end
	for _, cmd in ipairs(cmds) do
		vim.api.nvim_create_user_command(cmd, function(info)
			for _, c in ipairs(cmds) do
				pcall(vim.api.nvim_del_user_command, c)
			end
			if name then
				do_load(name, "cmd: " .. cmd)
			end
			protected("on_cmd(" .. (name or "anon") .. ")", fn)
			local call = cmd .. (info.args ~= "" and (" " .. info.args) or "")
			if info.bang then
				call = call .. "!"
			end
			pcall(function()
				vim.cmd(call)
			end)
		end, {
			nargs = "*",
			bang = true,
			desc = string.format("[pack] stub: loads '%s' on first use", name or "anon"),
		})
	end
end

---Lazy-load on autocmd event(s).
---@param event string|string[]
---@param fn fun()
---@param name string|nil
function M.on_event(event, fn, name)
	if name then
		assert(_state[name], string.format("[pack] on_event: '%s' is not registered", name))
	end

	vim.api.nvim_create_autocmd(event, {
		once = true,
		desc = string.format("[pack] on_event for '%s'", name or "anon"),
		callback = function()
			if name then
				do_load(name, "event")
			end
			protected("on_event(" .. (name or "anon") .. ")", fn)
		end,
	})
end

function M.on_lazy_file(fn, name)
	if name then
		assert(_state[name], string.format("[pack] on_event: '%s' is not registered", name))
	end
	local done = false
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePre" }, {
		desc = "[pack] lazy file trigger",
		callback = function(ev)
			if name then
				do_load(name, "event: lazy_file")
			end
			if done or vim.bo[ev.buf].buftype ~= "" or vim.api.nvim_buf_get_name(ev.buf) == "" then
				return
			end
			done = true
			local ok, err = pcall(fn)
			if not ok then
				notify.error("[pack] on_lazy_file() error: " .. err)
			end
		end,
	})
end

---Lazy-load
---@param fn   fun()
---@param name string?
function M.defer(fn, name)
	if name then
		assert(_state[name], string.format("[pack] defer: '%s' is not registered", name))
	end
	vim.api.nvim_create_autocmd("UIEnter", {
		once = true,
		desc = string.format("[pack] defer for '%s'", name or "anon"),
		callback = function()
			vim.schedule(function()
				if name then
					do_load(name, "defer")
				end
				protected("defer(" .. (name or "anon") .. ")", fn)
			end)
		end,
	})
end

---Schedule fn after the current event loop tick.
---@param fn fun()
function M.later(fn)
	vim.schedule(function()
		protected("later()", fn)
	end)
end

---True if the plugin is registered in this session or present on disk.
---@param name string
---@return boolean
function M.has(name)
	if _state[name] then
		return true
	end
	local path = vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. name
	return vim.uv.fs_stat(path) ~= nil
end

---True if the plugin is active in the current session.
---@param name string
---@return boolean
function M.is_loaded(name)
	if _state[name] and _state[name].loaded then
		return true
	end
	if vim.pack and vim.pack.info then
		local info = vim.pack.info(name)
		if info and info.active then
			if _state[name] then
				_state[name].loaded = true
			end
			return true
		end
	end
	return false
end

---@param names string|string[]?
function M.update(names)
	if not names then
		vim.ui.input({ prompt = "Update all plugins? y/N" }, function(input)
			if input and input:lower() == "y" then
				notify.info("[pack] updating all plugins…")
				vim.pack.update(nil, { force = true })
			end
		end)
		return
	end
	names = type(names) == "string" and { names } or names
	notify.info("[pack_ui] updating " .. names .. "…")
	---@diagnostic disable-next-line: param-type-mismatch
	vim.pack.update(names, { force = true })
end

local function get_opt_path()
	return vim.fn.stdpath("data") .. "/site/pack/core/opt"
end

---Return plugin names that exist on disk but are NOT registered in _state.
---@return string[]
function M.orphans()
	local path = get_opt_path()
	local orphans = {}
	local handle = vim.uv.fs_scandir(path)

	if not handle then
		return orphans
	end

	while true do
		local name, typ = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end
		if typ == "directory" and not _state[name] then
			table.insert(orphans, name)
		end
	end

	return orphans
end

---@return string[]
function M.clean()
	local removed = {}
	for _, name in ipairs(M.orphans()) do
		local ok, _ = pcall(vim.pack.del, { name })
		if ok then
			table.insert(removed, name)
		end
	end
	return removed
end

---@class Pack.Snapshot
---@field plugins table<string, Pack.state>
---@field orphans string[]

---Return a copy of the full state table (for a picker or debugger).
---@return Pack.Snapshot
function M.snapshot()
	return {
		plugins = vim.deepcopy(_state),
		orphans = M.orphans(),
	}
end

---@class Pack.ChangeParams
---@field name string
---@field path string
---@field kind string
---@field active boolean

---@alias Pack.ChangeKind
---| "install"
---| "update"
---| "delete"

---@return Pack.ChangeParams
local function make_params(ev)
	return {
		name = ev.data.spec.name,
		path = vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. ev.data.spec.name,
		kind = ev.data.kind,
		active = ev.data.active,
	}
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
		callback = function(ev)
			if ev.data.spec.name ~= name then
				return
			end
			if not allowed[ev.data.kind] then
				return
			end

			local params = make_params(ev)

			if not ev.data.active then
				vim.cmd.packadd(name)
			end
			local ok, err = pcall(fn, params)
			if not ok then
				notify.error(string.format("[pack] hook error for '%s': %s", name, err))
			end
		end,
	})
end

---@class Pack.lazy
---@field event string?
---@field cmd string|string[]?
---@field ft string|string[]?
---@field keys KeymapOpts[]?
---@field lazy_file boolean?
---@field defer boolean?
---@field config fun()?

---@param name string
---@param spec Pack.lazy
function M.lazy(name, spec)
	assert(_state[name], string.format("[pack] lazy: '%s' is not registered", name))

	local fn = spec.config
	local ran = false

	local function run_once()
		if ran then
			return
		end
		ran = true
		if fn then
			protected("lazy(" .. name .. ")", fn)
		end
	end

	if spec.event then
		M.on_event(spec.event, run_once, name)
	end
	if spec.cmd then
		M.on_cmd(spec.cmd, run_once, name)
	end
	if spec.ft then
		M.on_ft(spec.ft, run_once, name)
	end
	if spec.keys then
		M.on_key(spec.keys, run_once, name)
	end
	if spec.lazy_file then
		M.on_lazy_file(run_once, name)
	end
	if spec.defer then
		M.defer(run_once, name)
	end
end

return M
