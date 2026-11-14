---@class utils.treesitter.incr
local M = {}

-- Selection chain per buffer, so <BS> can walk back through it
local stacks = {} ---@type table<number, TSNode[]>

---@param buf number
---@return TSNode[]
local function get_stack(buf)
	stacks[buf] = stacks[buf] or {}
	return stacks[buf]
end

---@param row number
---@return number
local function line_length(row)
	return #(vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or "")
end

---Node range as 0-based, end-exclusive, with an end-of-line end pulled back to
---the last character so it compares equal to a visual selection
---@param node TSNode
---@return number[]
local function range(node)
	local srow, scol, erow, ecol = node:range()
	if ecol == 0 and erow > srow then
		erow, ecol = erow - 1, line_length(erow - 1)
	end
	return { srow, scol, erow, ecol }
end

---@param a number[]
---@param b number[]
---@return boolean
local function same(a, b)
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
end

---Current visual selection as a 0-based, end-exclusive range
---@return number[]
local function selection()
	local first, last = vim.fn.getpos("v"), vim.fn.getpos(".")
	local srow, scol, erow, ecol = first[2] - 1, first[3] - 1, last[2] - 1, last[3]
	if srow > erow or (srow == erow and scol > ecol) then
		srow, scol, erow, ecol = erow, ecol, srow, scol
	end
	return { srow, scol, erow, ecol }
end

---Select a node in visual mode
---@param node TSNode
local function select(node)
	local r = range(node)
	local srow, scol, erow, ecol = r[1], r[2], r[3], math.max(r[4] - 1, 0)

	local start = { 0, srow + 1, scol + 1, 0 }
	local stop = { 0, erow + 1, ecol + 1, 0 }

	vim.cmd.normal({ bang = true, "\27" })
	vim.fn.setpos(".", start)
	vim.cmd.normal({ bang = true, "v" })
	vim.fn.setpos(".", stop)
	vim.fn.setpos("'<", start)
	vim.fn.setpos("'>", stop)
end

---@param buf number
---@param language string
---@param sel number[]
---@return TSNode?
local function node_at(buf, language, sel)
	local ok, parser = pcall(vim.treesitter.get_parser, buf, language)
	if not ok or not parser then
		return nil
	end
	parser:parse()
	return parser:named_node_for_range(sel, { ignore_injections = false })
end

local CONTAINERS = { "list", "dict", "table", "array", "block", "expression", "statement", "call", "string" }

---Smallest node under the cursor, preferring a container over plain delimiters
---@param buf number
---@return TSNode?
local function initial_node(buf)
	local node = Utils.treesitter.get_node({ bufnr = buf })
	if not node then
		return nil
	end

	if node:type():match("^%p$") then
		local parent = node:parent()
		while parent and not vim.iter(CONTAINERS):any(function(t)
			return parent:type():match(t) ~= nil
		end) do
			parent = parent:parent()
		end
		node = parent or node
	end

	while node and not node:named() do
		node = node:parent()
	end
	return node
end

---@param node TSNode
---@return TSNode?
local function parent_of(node)
	local current = range(node)
	local parent = node:parent()
	while parent and same(range(parent), current) do
		parent = parent:parent()
	end
	return parent
end

---Nearest enclosing scope from the `locals` query
---@param buf number
---@param language string
---@param node TSNode
---@return TSNode?
local function scope_of(buf, language, node)
	local ok, parser = pcall(vim.treesitter.get_parser, buf, language)
	if not ok or not parser then
		return nil
	end
	local query = vim.treesitter.query.get(language, "locals")
	local trees = query and parser:parse()
	if not trees or not trees[1] then
		return nil
	end
	local root = trees[1]:root()

	local scopes = {}
	for _, match in query:iter_matches(root, buf) do
		for id, nodes in pairs(match) do
			if query.captures[id] == "local.scope" then
				vim.list_extend(scopes, nodes)
			end
		end
	end

	local parent = node:parent()
	while parent and not vim.tbl_contains(scopes, parent) do
		parent = parent:parent()
	end
	return parent
end

---@param buf number
---@param language string
---@param next_node? fun(node: TSNode): TSNode?
local function expand(buf, language, next_node)
	local stack = get_stack(buf)
	local sel = selection()
	local node = stack[#stack]

	-- Manually changed selection: start a new chain from it
	if not node or not same(range(node), sel) then
		stack = {}
		stacks[buf] = stack
		node = node_at(buf, language, sel)
	end

	local target = node and (next_node or parent_of)(node)
	if target then
		table.insert(stack, target)
		select(target)
	end
end

---Start selecting the node under the cursor
---@param buf number
function M.init_selection(buf)
	local node = initial_node(buf)
	if node then
		stacks[buf] = { node }
		select(node)
	end
end

---Expand the selection to the parent node
---@param buf number
---@param language string
function M.node_incremental(buf, language)
	expand(buf, language)
end

---Expand the selection to the enclosing scope
---@param buf number
---@param language string
function M.scope_incremental(buf, language)
	expand(buf, language, function(node)
		return scope_of(buf, language, node)
	end)
end

---Shrink the selection back down the chain (or to the node under the cursor)
---@param buf number
---@param language string
function M.node_decremental(buf, language)
	local stack = get_stack(buf)
	if stack[#stack] and same(range(stack[#stack]), selection()) then
		stack[#stack] = nil
	else
		stack, stacks[buf] = {}, {}
	end

	local node = stack[#stack]
	if not node then
		node = initial_node(buf)
		if node then
			table.insert(stack, node)
		end
	end
	if node then
		select(node)
	end
end

vim.api.nvim_create_autocmd("BufDelete", {
	callback = function(args)
		stacks[args.buf] = nil
	end,
})

return M
