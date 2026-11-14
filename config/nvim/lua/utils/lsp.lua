---@class utils.lsp
local M = {}

local notify = Utils.notify.create({ title = "LSP" })

---@class LspHandler
---@field filter table
---@field callback fun(client: vim.lsp.Client, buf: number)
---@field done table<string, boolean>

local handlers = {} ---@type LspHandler[]
local did_setup = false

---------------------------------------------------------------
---Normalize LSP method names (add textDocument/ prefix if needed)
---@param method string
---@return string
---------------------------------------------------------------
local function normalize_method(method)
	return method:find("/") and method or ("textDocument/" .. method)
end

---------------------------------------------------------------
---@param client vim.lsp.Client
---@param buf number
---@param filter table
---@return boolean
---------------------------------------------------------------
local function matches(client, buf, filter)
	return (not filter.id or client.id == filter.id)
		and (not filter.name or client.name == filter.name)
		and (not filter.bufnr or buf == filter.bufnr)
		and (not filter.method or client:supports_method(filter.method, buf))
end

---------------------------------------------------------------
---@param handler LspHandler
---@param client vim.lsp.Client
---@param buf number
---------------------------------------------------------------
local function run(handler, client, buf)
	local key = string.format("%d:%d", client.id, buf)
	if handler.done[key] or not matches(client, buf, handler.filter) then
		return
	end
	handler.done[key] = true
	local ok, err = pcall(handler.callback, client, buf)
	if not ok then
		notify.error(string.format("LSP callback error for %s (buf %d): %s", client.name, buf, err))
	end
end

---------------------------------------------------------------
---Setup LSP keymap handlers (autocmds for attach/detach)
---------------------------------------------------------------
function M.setup()
	if did_setup then
		return
	end
	did_setup = true

	local group = vim.api.nvim_create_augroup("utils.lsp", { clear = true })
	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(ev)
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if not client then
				return
			end
			vim.schedule(function()
				for _, handler in ipairs(handlers) do
					run(handler, client, ev.buf)
				end
			end)
		end,
	})
	vim.api.nvim_create_autocmd("LspDetach", {
		group = group,
		callback = function(ev)
			local key = string.format("%d:%d", ev.data.client_id, ev.buf)
			for _, handler in ipairs(handlers) do
				handler.done[key] = nil
			end
		end,
	})
end

---------------------------------------------------------------
---@param filter vim.lsp.get_clients.Filter Filter can include:
---@param callback fun(client: vim.lsp.Client, buffer: number)
---------------------------------------------------------------
function M.on(filter, callback)
	M.setup()
	if filter.method then
		filter = vim.deepcopy(filter)
		filter.method = normalize_method(filter.method)
	end

	local handler = { filter = filter, callback = callback, done = {} }
	table.insert(handlers, handler)

	for _, client in ipairs(vim.lsp.get_clients()) do
		for buf in pairs(client.attached_buffers) do
			run(handler, client, buf)
		end
	end
end

function M.on_attach(callback)
	M.on({}, callback)
end

---------------------------------------------------------------
---Register callback for a specific LSP server
---@param server_name string
---@param callback fun(client: vim.lsp.Client, buffer: number)
---------------------------------------------------------------
function M.on_server(server_name, callback)
	M.on({ name = server_name }, callback)
end

---------------------------------------------------------------
---Register callback for a specific LSP method/capability
---@param method string LSP method (e.g., "formatting", "hover", "codeAction")
---@param callback fun(client: vim.lsp.Client, buffer: number)
---------------------------------------------------------------
function M.on_method(method, callback)
	M.on({ method = method }, callback)
end

----------------------------------------------------
-- Get a list of active LSP clients
---@param opts table?
---@return vim.lsp.Client[]
----------------------------------------------------
function M.get_clients(opts)
	local ret = {} ---@type vim.lsp.Client[]
	if vim.lsp.get_clients then
		ret = vim.lsp.get_clients(opts)
	end
	return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end

----------------------------------------------------
-- Action metatable for LSP code actions
---@return table Metatable for LSP code actions
----------------------------------------------------
M.action = setmetatable({}, {
	__index = function(_, action)
		return function()
			vim.lsp.buf.code_action({
				apply = true,
				context = {
					only = { action },
					diagnostics = {},
				},
			})
		end
	end,
})

----------------------------------------------------
--- Check if a specific LSP method is supported
--- @param buffer number Buffer number
--- @param method string|string[] LSP method or array of methods to check
--- @return boolean Whether the method(s) is supported
----------------------------------------------------
function M.has(buffer, method)
	if type(method) == "table" then
		return vim.iter(method):any(function(m)
			return M.has(buffer, m)
		end)
	end
	for _, client in ipairs(M.get_clients({ bufnr = buffer })) do
		local capability = client.server_capabilities[method .. "Provider"]
		if capability ~= nil and capability ~= false then
			return true
		end
	end
	return false
end

----------------------------------------------------
--- Navigate to next or previous diagnostic
--- @param next boolean Whether to go to next (true) or previous (false) diagnostic
--- @param severity? string Diagnostic severity level
--- @return function Diagnostic navigation function
----------------------------------------------------
function M.goto_diagnostics(next, severity)
	local count = next and 1 or -1
	local sev = severity and vim.diagnostic.severity[severity:upper()] or nil

	return function()
		vim.diagnostic.jump({
			count = count,
			severity = sev,
		})
	end
end

-----------------------------------------------
-- copy the diagnostic message under the cursor
-----------------------------------------------
function M.copy_diagnostics()
	local diags = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
	if #diags == 0 then
		notify.warn("No diagnostics found in current line")
		return
	end

	---@param msg string
	local function yank(msg)
		vim.fn.setreg('"', msg)
		vim.fn.setreg(vim.v.register, msg)
	end

	if #diags == 1 then
		local msg = diags[1].message
		yank(msg)
		notify(string.format([[ yanked diagnostic message '%s']], msg))
		return
	end

	vim.ui.select(
		vim.tbl_map(function(d)
			return d.message
		end, diags),
		{ prompt = "Select diagnostic message to yank: " },
		yank
	)
end

---@param name string
---@return boolean
function M.stop(name)
	local clients = M.get_clients({ name = name })
	if #clients == 0 then
		notify.warn(string.format("Server '%s' is not running", name))
		return false
	end

	for _, client in ipairs(clients) do
		pcall(function()
			client:stop(true)
		end)
	end

	return true
end

---@param name string
---@return boolean
function M.start(name, bufnr)
	bufnr = Utils.fn.ensure_buf(bufnr)
	local existing = M.get_clients({ name = name, bufnr = bufnr })
	if #existing > 0 then
		notify.info(string.format("Server '%s' is already running on buffer %d", name, bufnr))
		return true
	end
	local ok, err = pcall(vim.lsp.enable, name)
	if not ok then
		notify.error(string.format("Failed to start server '%s': %s", name, err))
		return false
	end
	return true
end

---@param name string
---@return boolean
function M.restart(name, bufnr)
	bufnr = Utils.fn.ensure_buf(bufnr)
	local clients = M.get_clients({ name = name })
	if #clients == 0 then
		notify.warn(string.format("Server '%s' is not running, starting it instead", name))
		return M.start(name, bufnr)
	end
	if not M.stop(name) then
		return false
	end
	vim.defer_fn(function()
		M.start(name, bufnr)
		notify.info(string.format("Restarted server '%s'", name), { title = "LSP" })
	end, 500)
	return true
end

---@param item table
local function jump(item)
	if not item.filename then
		notify.error("Invalid definition result: no filename")
		return
	end
	local win = vim.fn.bufwinid(vim.fn.bufadd(item.filename))
	if win ~= -1 then
		vim.api.nvim_set_current_win(win)
	else
		vim.cmd("edit " .. vim.fn.fnameescape(item.filename))
	end
	pcall(vim.api.nvim_win_set_cursor, 0, { item.lnum, math.max(item.col - 1, 0) })
end

----------------------------------------------------
--- Go to first definition with window reuse and split options
---@param opts? { direction?: "split"|"vsplit" }
---   - reuse_win: boolean - Whether to reuse existing windows (default: true)
----------------------------------------------------
function M.goto_definition(opts)
	opts = opts or {}
	vim.lsp.buf.definition({
		on_list = function(list)
			local items = list.items
			if not items or #items == 0 then
				notify.warn("No definition found")
				return
			end
			if #items > 1 then
				Snacks.picker.lsp_definitions()
				return
			end

			local item = items[1]
			vim.cmd("normal! m'")
			if opts.direction then
				local cmd = opts.direction == "split" and "split" or "vsplit"
				vim.cmd(cmd .. " " .. vim.fn.fnameescape(item.filename))
				pcall(vim.api.nvim_win_set_cursor, 0, { item.lnum, math.max(item.col - 1, 0) })
			else
				jump(item)
			end
			vim.cmd("normal! zz")
		end,
	})
end

---------------------------------------------------------------
---Prepare keymap options for buffer-local LSP keymap
---@param mapping KeymapOpts Original mapping with LSP fields
---@param buf number Buffer number
---@return KeymapOpts? opts Returns nil if keymap shouldn't be set
---------------------------------------------------------------
function M.map(mapping, buf)
	if mapping.has and not M.has(buf, mapping.has) then
		return nil
	end
	local opts = vim.tbl_extend("force", {}, mapping)
	opts.buffer = buf
	opts.lsp = nil
	opts.has = nil
	opts.enabled = nil
	return opts
end

return M
