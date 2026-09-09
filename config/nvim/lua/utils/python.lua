---@class utils.python
local M = {}

---@class StringInfo
---@field is_fstring boolean
---@field prefix_row integer
---@field prefix_col integer

---@param bufnr integer
---@param row integer
---@param col integer
---@return StringInfo?
local function get_string_info(bufnr, row, col)
	local node = Utils.treesitter.find_node("^string$", { bufnr = bufnr, pos = { row, col } })
	if not node then
		return nil
	end

	local start_node
	for child in node:iter_children() do
		if child:type() == "string_start" then
			start_node = child
			break
		end
	end
	if not start_node then
		return nil
	end

	local prefix_text = vim.treesitter.get_node_text(start_node, bufnr)
	local srow, scol = start_node:start()

	return {
		is_fstring = prefix_text:lower():find("f", 1, true) ~= nil,
		prefix_row = srow,
		prefix_col = scol,
	}
end

---@type {row: integer, col: integer, info: StringInfo?}?
local pending_brace

function M.handle_brace()
	local win = vim.api.nvim_get_current_win()
	local bufnr = vim.api.nvim_win_get_buf(win)
	local row, col = unpack(vim.api.nvim_win_get_cursor(win))
	row = row - 1

	local function insert(text, new_col)
		vim.api.nvim_buf_set_text(bufnr, row, col, row, col, { text })
		vim.api.nvim_win_set_cursor(win, { row + 1, new_col })
	end

	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
	local prev_char = col > 0 and line:sub(col, col) or ""

	local continues_pending = prev_char == "{"
		and pending_brace
		and pending_brace.row == row
		and pending_brace.col == col - 1

	local info = continues_pending and (pending_brace and pending_brace.info) or get_string_info(bufnr, row, col)

	if not info then
		pending_brace = { row = row, col = col, info = nil }
		insert("{}", col + 1)
		return
	end

	if info.is_fstring then
		pending_brace = { row = row, col = col, info = info }
		insert("{", col + 1)
		return
	end

	if not continues_pending then
		pending_brace = { row = row, col = col, info = info }
		insert("{", col + 1)
		return
	end

	pending_brace = nil
	local brace_pos = col - 1
	vim.api.nvim_buf_set_text(bufnr, info.prefix_row, info.prefix_col, info.prefix_row, info.prefix_col, { "f" })
	if info.prefix_row == row then
		brace_pos = brace_pos + 1
	end
	vim.api.nvim_buf_set_text(bufnr, row, brace_pos, row, brace_pos + 1, { "{}" })
	vim.api.nvim_win_set_cursor(win, { row + 1, brace_pos + 1 })
end

---@class VenvInfo
---@field venv_path string
---@field python_path string

local active_venv = nil ---@type string?
local venv_cache = {} ---@type table<string, VenvInfo|false>

---@param root string?
---@return VenvInfo?
function M.detect_venv(root)
	root = root or Utils.root()

	local cached = venv_cache[root]
	if cached ~= nil then
		if cached and vim.fn.isdirectory(cached.venv_path) == 1 and Utils.fn.is_executable(cached.python_path) then
			return cached
		end
		venv_cache[root] = nil
	end

	local function remember(result)
		venv_cache[root] = result or false
		return result
	end

	local current_venv = vim.env.VIRTUAL_ENV
	if current_venv and vim.startswith(current_venv, root) then
		return remember({ venv_path = current_venv, python_path = current_venv .. "/bin/python" })
	end

	for _, name in ipairs({ ".venv", "venv", ".virtualenv", "env" }) do
		local venv_path = root .. "/" .. name
		local python_path = venv_path .. "/bin/python"
		if Utils.fn.is_executable(python_path) then
			return remember({ venv_path = venv_path, python_path = python_path })
		end
	end

	return remember(nil)
end

---@param venv_info VenvInfo?
---@return boolean
local function apply_venv(venv_info)
	if not venv_info or active_venv == venv_info.venv_path then
		return false
	end
	vim.env.VIRTUAL_ENV = venv_info.venv_path
	Utils.fn.add_to_path(venv_info.venv_path .. "/bin")
	vim.g.python3_host_prog = venv_info.python_path
	active_venv = venv_info.venv_path
	return true
end

---@param root string?
---@return VenvInfo?
function M.activate_venv(root)
	local venv_info = M.detect_venv(root)
	if venv_info and apply_venv(venv_info) then
		Utils.notify.info("venv: " .. venv_info.venv_path)
	end
	return venv_info
end

return M
