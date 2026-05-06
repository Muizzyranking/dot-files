---@class LspExtras
---@field enabled? boolean
---@field keys? KeymapOpts[]
---@field on_attach? fun(client: table, bufnr: number)

local config_dir = vim.fn.stdpath("config")
local lsp_dir = config_dir .. "/lsp"
local extras_base = config_dir .. "/lua/lsp/extras"

local config = {
	codelens = {
		enabled = false,
		events = { "BufEnter", "CursorHold", "InsertLeave" },
	},
	document_color = { enabled = true },
	document_highlight = { enabled = true, delay = 100 },
	folds = { enabled = true },
	semantic_tokens = {
		enabled = true,
		disable_for = { "lua_ls" },
	},
}

local Features = {}

function Features.codelens(opts)
	Utils.lsp.on_method("textDocument/codeLens", function(_, buf)
		vim.lsp.codelens.enable(true, { bufnr = buf })
		vim.api.nvim_create_autocmd(opts.events, {
			buffer = buf,
			callback = function()
				vim.lsp.codelens.enable(true, { bufnr = buf })
			end,
		})
	end)
end

function Features.document_color(_)
	Utils.lsp.on_method("textDocument/documentColor", function(_, buf)
		if vim.lsp.document_color ~= nil then
			vim.lsp.document_color.enable(true, { bufnr = buf })
		end
	end)
end

function Features.document_highlight(opts)
	if opts.delay then
		vim.opt.updatetime = opts.delay
	end
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
end

function Features.folds()
	Utils.lsp.on_method("textDocument/foldingRange", function(_, buf)
		local win = vim.api.nvim_get_current_win()
		if vim.api.nvim_win_get_buf(win) == buf then
			vim.wo[win].foldmethod = "expr"
			vim.wo[win].foldexpr = "v:lua.vim.lsp.foldexpr()"
		end
	end)
end

function Features.semantic_tokens(opts)
	local disable_map = {}
	for _, server in ipairs(opts.disable_for or {}) do
		disable_map[server] = true
	end
	Utils.lsp.on_attach(function(client, _)
		if disable_map[client.name] then
			client.server_capabilities.semanticTokensProvider = nil
		end
	end)
end

local function init_features()
	for name, opts in pairs(config) do
		if opts.enabled then
			local fn = Features[name]
			if fn then
				fn(opts)
			end
		end
	end
end

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

			if not extras or extras.enabled ~= false then
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

local function apply_global_keymaps()
	Utils.lsp.on_attach(function()
		Utils.map.del({ "gra", "grn", "grr", "gri", "grt" })
	end)
	local keys = load_global_keymaps()
	if keys and #keys > 0 then
		Utils.map.set(keys, { lsp = true })
	end
end

local function setup_diagnostics()
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
end

local function setup_capabilities()
	vim.lsp.config("*", {
		capabilities = {
			workspace = {
				didChangeWatchedFiles = {
					dynamicRegistration = true,
					relativePatternSupport = true,
				},
				fileOperations = {
					didRename = true,
					willRename = true,
				},
			},
		},
	})
end

local servers = scan_servers()

init_features()
apply_global_keymaps()
setup_diagnostics()
setup_capabilities()

--- load servers after mason is ready to ensure executable are available
Pack.on_load("mason.nvim", function()
	vim.schedule(function()
		vim.lsp.enable(servers)
		vim.api.nvim_exec_autocmds("FileType", {
			buffer = vim.api.nvim_get_current_buf(),
			modeline = false,
		})
	end)
end)
