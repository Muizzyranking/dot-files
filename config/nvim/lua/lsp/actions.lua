local M = {}

---@class LspPickerItem
---@field text string
---@field name string
---@field [any] any

M.ignored_servers = { "copilot" }

---@param name string
---@return boolean
local function is_ignored(name)
	return vim.tbl_contains(M.ignored_servers, name)
end

---@return table[]
local function get_running_servers()
	local items = {}
	for _, client in ipairs(vim.lsp.get_clients()) do
		if not is_ignored(client.name) then
			table.insert(items, {
				text = string.format("%s (id: %d)", client.name, client.id),
				name = client.name,
			})
		end
	end
	if #items == 0 then
		Utils.notify.warn("No LSP servers currently running")
	end
	return items
end

---@return string[]
local function get_all_servers()
	local servers = {}
	for name, ftype in vim.fs.dir(Utils.fn.fmt_str("${CONFIG_DIR}/lsp")) do
		if ftype == "file" and name:match("%.lua$") then
			local server = name:gsub("%.lua$", "")
			if not is_ignored(server) then
				table.insert(servers, server)
			end
		end
	end
	return servers
end

---@param icon string
---@param hl string
local function format(icon, hl)
	return function(item)
		return { { icon, hl }, { item.text } }
	end
end

---@param opts table
---@return function
local function picker(opts)
	return function()
		return Snacks.picker(vim.tbl_deep_extend("force", {
			layout = { preset = "drop", preview = false },
			on_show = function()
				vim.cmd("stopinsert")
			end,
			win = { input = { keys = { ["<CR>"] = { "confirm", mode = { "n", "i" } } } } },
			actions = {
				confirm = function(p)
					local selected = p:selected({ fallback = true })
					p:close()
					opts.on_confirm(selected)
				end,
			},
		}, opts))
	end
end

M.restart_picker = picker({
	title = "Restart LSP Servers",
	finder = get_running_servers,
	format = format("󰒋 ", "DiagnosticOk"),
	on_confirm = function(selected)
		for _, item in ipairs(selected) do
			Utils.lsp.restart(item.name)
		end
	end,
})

M.stop_picker = picker({
	title = "Stop LSP Servers",
	finder = get_running_servers,
	format = format("󰒋 ", "DiagnosticError"),
	on_confirm = function(selected)
		for _, item in ipairs(selected) do
			Utils.lsp.stop(item.name)
		end
	end,
})

M.start_picker = picker({
	title = "Start LSP Servers",
	finder = function()
		local running = {}
		for _, client in ipairs(vim.lsp.get_clients()) do
			running[client.name] = true
		end

		local items = {}
		for _, name in ipairs(get_all_servers()) do
			if not running[name] then
				table.insert(items, { text = name, name = name })
			end
		end
		if #items == 0 then
			Utils.notify.info("All enabled servers are already running")
			return {}
		end
		return items
	end,
	format = format("󰒌 ", "DiagnosticWarn"),
	on_confirm = function(selected)
		for _, item in ipairs(selected) do
			Utils.lsp.start(item.name)
		end
	end,
})

function M.restart_all_attached()
	local clients = get_running_servers()
	if #clients == 0 then
		Utils.notify.warn("No LSP servers attached to current buffer")
		return
	end
	for _, client in ipairs(clients) do
		Utils.lsp.restart(client.name)
	end
end

function M.lsp_info()
	vim.cmd("checkhealth vim.lsp")
end

return M
