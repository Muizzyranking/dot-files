---@class utils.treesitter
local M = {}
M.incr = {}

-------------------------------------------------
---Only checks whether treesitter highlighting is active in `buf`
---Should be faster than `M.is_active()`
---@param buf number? # default: current buffer
---@return boolean
-------------------------------------------------
function M.hl_is_active(buf)
	buf = Utils.fn.ensure_buf(buf)
	return vim.treesitter.highlighter.active[buf] ~= nil
end

-------------------------------------------------
---Returns whether treesitter is active in `buf`
---@param buf number? default: current buffer
---@return boolean
-------------------------------------------------
function M.is_active(buf)
	buf = Utils.fn.ensure_buf(buf)
	return vim.treesitter.highlighter.active[buf] ~= nil or pcall(vim.treesitter.get_parser, buf)
end

-------------------------------------------------
---Wrapper of `vim.treesitter.get_node()` that fixes the cursor pos in
---insert mode
---@param opts vim.treesitter.get_node.Opts?
-------------------------------------------------
function M.get_node(opts)
	opts = opts or {}
	if opts.pos or opts.bufnr and opts.bufnr ~= 0 and opts.bufnr ~= vim.api.nvim_get_current_buf() then
		return vim.treesitter.get_node(opts)
	end
	local cursor = vim.api.nvim_win_get_cursor(0)
	opts.pos = {
		cursor[1] - 1,
		cursor[2] - (cursor[2] >= 1 and vim.startswith(vim.fn.mode(), "i") and 1 or 0),
	}
	return vim.treesitter.get_node(opts)
end

------------------------------------------------
---Returns whether cursor is in a specific type of treesitter node
---@param types string|string[]|fun(types: string|string[]): boolean # type of node, or function to check node type
---@param opts vim.treesitter.get_node.Opts?
---@return TSNode?
------------------------------------------------
function M.find_node(types, opts)
	if not M.is_active(opts and opts.bufnr) then
		return
	end

	---@type fun(t: string): boolean?
	local check_type_match = vim.is_callable(types) and function(nt)
		return types(nt)
	end or function(nt)
		types = Utils.fn.ensure_list(types)
		return vim.iter(types):any(function(t)
			return nt:match(t)
		end)
	end

	local node = M.get_node(opts)
	while node do
		if check_type_match(node:type()) then
			return node
		end
		node = node:parent()
	end
end

M._installed = nil ---@type table<string,string>?

-----------------------------------------
---Get list of installed treesitter parsers
---@param force boolean?
---@return table<string,string>
-----------------------------------------
function M.get_installed(force)
	if not M._installed or force then
		M._installed = {}
		for _, lang in ipairs(require("nvim-treesitter").get_installed("parsers")) do
			M._installed[lang] = lang
		end
	end
	return M._installed
end

-----------------------------------------
---Check if treesitter parser is available for filetype
---@param ft string # filetype
---@return string?
-----------------------------------------
function M.have(ft)
	if not ft or ft == "" then
		return nil
	end
	local lang = vim.treesitter.language.get_lang(ft)
	return lang and M.get_installed()[lang]
end

function M.foldexpr()
	local buf = vim.api.nvim_get_current_buf()
	return M.have(vim.bo[buf].filetype) and vim.treesitter.foldexpr() or "0"
end

function M.indentexpr()
	local buf = vim.api.nvim_get_current_buf()
	return M.have(vim.bo[buf].filetype) and require("nvim-treesitter").indentexpr() or -1
end

---Ensure treesitter is active and parser is available
---@return boolean, number?, string?
function M.incr.ensure_active()
	local buf = Utils.fn.ensure_buf(0)
	local ft = vim.bo[buf].filetype
	if not M.is_active(buf) then
		return false
	end
	local language = vim.treesitter.language.get_lang(ft)
	if not language or not M.have(ft) then
		return false
	end
	return true, buf, language
end

local INCR_KEYS = {
	init_selection = { "n", "Init incremental selection" },
	node_incremental = { "x", "Node incremental" },
	scope_incremental = { "x", "Scope incremental" },
	node_decremental = { "x", "Node decremental" },
}

---@param opts table<string, string> action -> lhs
function M.incr.attach(opts)
	local incr = require("utils.treesitter.incr")
	for action, config in pairs(INCR_KEYS) do
		local lhs = opts and opts[action]
		if lhs and lhs ~= "" then
			vim.keymap.set(config[1], lhs, function()
				local active, buf, language = M.incr.ensure_active()
				if active then
					incr[action](buf, language)
				end
			end, { desc = config[2] })
		end
	end
end

return M
