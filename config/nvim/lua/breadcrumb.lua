local M = {}

local default_config = {
	separator = "  ",
	icons = Utils.icons.kinds,
	kind_highlights = true,
	excluded_filetypes = {
		"help",
		"NvimTree",
		"mason",
		"oil",
	},
	debounce_ms = 80,
	fallback = " ",
}

local config = vim.deepcopy(default_config)

local symbol_cache = {}
local update_seq = {}

local kind_names = {}
for name, num in pairs(vim.lsp.protocol.SymbolKind or {}) do
	if type(num) == "number" then
		kind_names[num] = name
	end
end

local DOC_SYMBOL_METHOD = "textDocument/documentSymbol"

local function find_document_symbol_client(bufnr)
	local clients = Utils.lsp.get_clients({ bufnr = bufnr, method = DOC_SYMBOL_METHOD })
	return clients[1]
end

local function request_symbols(bufnr, callback)
	local client = find_document_symbol_client(bufnr)
	if not client then
		callback(nil)
		return
	end
	local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
	client:request(DOC_SYMBOL_METHOD, params, function(err, result)
		if err or not result then
			callback(nil)
		else
			callback(result)
		end
	end, bufnr)
end

local function in_range(pos, range)
	local line, char = pos[1], pos[2]
	local s, e = range["start"], range["end"]
	if line < s.line or line > e.line then
		return false
	end
	if line == s.line and char < s.character then
		return false
	end
	if line == e.line and char > e.character then
		return false
	end
	return true
end

local function find_path(symbols, pos, path)
	path = path or {}
	if not symbols then
		return path
	end
	for _, symbol in ipairs(symbols) do
		local range = symbol.range or (symbol.location and symbol.location.range)
		if range and in_range(pos, range) then
			table.insert(path, symbol)
			if symbol.children and #symbol.children > 0 then
				find_path(symbol.children, pos, path)
			end
			break
		end
	end
	return path
end

local function escape_statusline(str)
	return (str:gsub("%%", "%%%%"))
end

local function kind_icon_and_name(kind_num)
	local name = kind_names[kind_num] or "Field"
	return config.icons[name] or "", name
end

local function build_winbar(path)
	if #path == 0 then
		return config.fallback
	end

	local parts = {}
	for i, symbol in ipairs(path) do
		local icon, kind_name = kind_icon_and_name(symbol.kind)
		local hl = config.kind_highlights and ("%#BreadcrumbKind" .. kind_name .. "#") or "%#BreadcrumbKind#"
		local sep = i == 1 and " " or config.separator
		table.insert(parts, sep .. hl .. icon .. "%*%#BreadcrumbText#" .. escape_statusline(symbol.name) .. "%*")
	end
	return table.concat(parts, "")
end

local function set_winbar_for_buf(bufnr, text)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == bufnr then
			vim.wo[win].winbar = text
		end
	end
end

local function paint_windows(bufnr, symbols)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == bufnr then
			local cursor = vim.api.nvim_win_get_cursor(win)
			local pos = { cursor[1] - 1, cursor[2] }
			local path = symbols and find_path(symbols, pos) or {}
			vim.wo[win].winbar = build_winbar(path)
		end
	end
end

local function update(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local ft = vim.bo[bufnr].filetype
	if vim.tbl_contains(config.excluded_filetypes, ft) then
		return
	end

	if not Utils.lsp.has(bufnr, "documentSymbol") then
		set_winbar_for_buf(bufnr, "")
		symbol_cache[bufnr] = nil
		return
	end

	if symbol_cache[bufnr] then
		paint_windows(bufnr, symbol_cache[bufnr])
	else
		set_winbar_for_buf(bufnr, config.fallback)
	end

	request_symbols(bufnr, function(symbols)
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end
		if symbols then
			symbol_cache[bufnr] = symbols
		end
		paint_windows(bufnr, symbol_cache[bufnr])
	end)
end

local function debounced_update(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	update_seq[bufnr] = (update_seq[bufnr] or 0) + 1
	local seq = update_seq[bufnr]
	vim.defer_fn(function()
		if update_seq[bufnr] == seq then
			update(bufnr)
		end
	end, config.debounce_ms)
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})

	local function hi(name, link)
		if vim.fn.hlexists(name) == 0 then
			vim.api.nvim_set_hl(0, name, { link = link, default = true })
		end
	end
	hi("BreadcrumbKind", "Function")
	hi("BreadcrumbText", "Normal")
	for _, name in pairs(kind_names) do
		hi("BreadcrumbKind" .. name, "Function")
	end

	Utils.lsp.on({ method = DOC_SYMBOL_METHOD }, function(_, bufnr)
		debounced_update(bufnr)
	end)

	local group = vim.api.nvim_create_augroup("BreadcrumbWinbar", { clear = true })

	vim.api.nvim_create_autocmd(
		{ "BufEnter", "WinEnter", "CursorMoved", "CursorMovedI", "InsertLeave", "TextChanged" },
		{
			group = group,
			callback = function(args)
				if Utils.lsp.has(args.buf, "documentSymbol") then
					debounced_update(args.buf)
				end
			end,
		}
	)

	vim.api.nvim_create_autocmd("LspDetach", {
		group = group,
		callback = function(args)
			vim.schedule(function()
				if not Utils.lsp.has(args.buf, "documentSymbol") then
					set_winbar_for_buf(args.buf, "")
					symbol_cache[args.buf] = nil
				end
			end)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = group,
		callback = function(args)
			symbol_cache[args.buf] = nil
			update_seq[args.buf] = nil
		end,
	})
end

function M.refresh(bufnr)
	update(bufnr or vim.api.nvim_get_current_buf())
end

return M
