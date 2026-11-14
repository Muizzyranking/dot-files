---@class LspExtras
---@field enabled? boolean | fun(settings: Settings): boolean
---@field keys? KeymapOpts[]
---@field on_attach? fun(client: vim.lsp.Client, bufnr: number)

local capabilities = {
	workspace = {
		didChangeWatchedFiles = { dynamicRegistration = true, relativePatternSupport = true },
		fileOperations = { didRename = true, willRename = true },
	},
}

vim.lsp.config("*", { capabilities = capabilities })

local lsp_dir = Utils.fn.fmt_str("${CONFIG_DIR}/lsp")
local extras_base = Utils.fn.fmt_str("${CONFIG_DIR}/lua/lsp/extras")

Utils.lsp.on_method("textDocument/documentColor", function(_, buf)
	if vim.lsp.document_color ~= nil then
		vim.lsp.document_color.enable(true, { bufnr = buf })
	end
end)

vim.opt.updatetime = 100
Utils.lsp.on_method("textDocument/documentHighlight", function(client, buf)
	local group = vim.api.nvim_create_augroup("lsp_highlight", { clear = true })
	vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
		group = group,
		buffer = buf,
		callback = vim.lsp.buf.document_highlight,
	})
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = group,
		buffer = buf,
		callback = vim.lsp.buf.clear_references,
	})
	vim.api.nvim_create_autocmd("LspDetach", {
		group = group,
		buffer = buf,
		callback = function(ev)
			if ev.data.client_id == client.id then
				pcall(vim.lsp.buf.clear_references)
				vim.api.nvim_del_augroup_by_id(group)
			end
		end,
	})
end)

Utils.lsp.on_method("textDocument/foldingRange", function(_, buf)
	local win = vim.api.nvim_get_current_win()
	if vim.api.nvim_win_get_buf(win) == buf then
		vim.wo[win].foldmethod = "expr"
		vim.wo[win].foldexpr = "v:lua.vim.lsp.foldexpr()"
	end
end)

local disable_for = { "lua_ls" }
local disable_map = {}
for _, server in ipairs(disable_for or {}) do
	disable_map[server] = true
end
Utils.lsp.on_attach(function(client, _)
	if disable_map[client.name] then
		client.server_capabilities.semanticTokensProvider = nil
	end
end)

local function load_global_keymaps()
	local ok, keys = pcall(require, "lsp.keymaps")
	return ok and keys or {}
end

---@param server_name string
---@return LspExtras?
local function load_server_extras(server_name)
	local extras_path = extras_base .. "/" .. server_name .. ".lua"
	if not vim.uv.fs_stat(extras_path) then
		return nil
	end

	local ok, result = pcall(require, "lsp.extras." .. server_name)
	if not ok then
		Utils.notify.warn("[lsp] Failed to load extras for " .. server_name .. ": " .. tostring(result))
		return nil
	end

	return type(result) == "table" and result or nil
end

local function scan_servers()
	local entries = vim.uv.fs_scandir(lsp_dir)
	local servers = {}
	if not entries then
		return {}
	end

	while true do
		local name, ftype = vim.uv.fs_scandir_next(entries)
		if not name then
			break
		end

		if ftype == "file" and name:match("%.lua$") then
			local server_name = name:gsub("%.lua$", "")
			local extras = load_server_extras(server_name)

			local function resolve_enabled(x)
				if x == nil then
					return true
				end
				if x.enabled == nil then
					return true
				end

				local enabled = x.enabled
				return Utils.fn.evaluate(enabled)
			end

			if resolve_enabled(extras) then
				table.insert(servers, server_name)

				if extras then
					if extras.keys and #extras.keys > 0 then
						Utils.map.set(extras.keys, { lsp = { name = server_name } })
					end
					if type(extras.on_attach) == "function" then
						Utils.lsp.on_server(server_name, function(client, bufnr)
							extras.on_attach(client, bufnr)
						end)
					end
				end
			end
		end
	end
	return servers
end

Utils.lsp.on_attach(function()
	Utils.map.del({ "gra", "grn", "grr", "gri", "grt" })
end)
local keys = load_global_keymaps()
if keys and #keys > 0 then
	Utils.map.set(keys, { lsp = true })
end

vim.diagnostic.config({
	underline = true,
	update_in_insert = false,
	virtual_text = true,
	float = {
		border = "single",
		source = true,
		max_width = 100,
	},
	severity_sort = true,
	signs = (function()
		local signs = { text = {}, numhl = {} }
		for name, icon in pairs(Utils.icons.diagnostics) do
			local severity = vim.diagnostic.severity[name:upper()]
			signs.text[severity] = icon
			signs.numhl[severity] = "DiagnosticSign" .. name
		end
		return signs
	end)(),
})

local servers = scan_servers()

vim.lsp.enable(servers)
