---@class utils.map
local M = {}

M = setmetatable(M, {
	__call = function(m, mode, lhs, rhs, opts)
		return m.safe_keymap_set(mode, lhs, rhs, opts)
	end,
})

---@alias KeymapMode
---| "n" # Normal mode
---| "i" # Insert mode
---| "v" # Visual mode
---| "x" # Visual block mode
---| "s" # Select mode
---| "o" # Operator pending mode
---| "t" # Terminal mode
---| "c" # Command mode

---@alias AbbrevConds
---| "lsp_keyword"

---@class ToggleIconConfig
---@field enabled? string # Icon when feature is enabled
---@field disabled? string # Icon when feature is disabled

---@class ToggleColorConfig
---@field enabled? string # Color when feature is enabled (e.g., "green")
---@field disabled? string # Color when feature is disabled (e.g., "yellow")

---@class AbbrevOpts
---@field mode? string # Mode for the abbreviation (default: "ia")
---@field conds? AbbrevConds|function|(AbbrevConds|function)[] # Conditions to check before applying abbreviation
---@field expr? boolean # Whether to treat as expression mapping
---@field buffer? number # Buffer number for buffer-local abbreviation
---@field desc? string # Description for the abbreviation
---@field silent? boolean # Whether to silence the abbreviation
---@field noremap? boolean # Whether to use noremap
---@field nowait? boolean # Whether to use nowait

---@class Abbrevs
---@field [1] string # The correct word/replacement
---@field [2] string|string[] # The word(s) to abbreviate (misspellings)
---@field [3]? AbbrevOpts # Optional abbreviation-specific options

---@class BaseMapping
---@field [1] string # The left-hand side of the mapping
---@field mode? KeymapMode|KeymapMode[]
---@field desc? string|function
---@field buffer? number|boolean
---@field silent? boolean
---@field remap? boolean
---@field expr? boolean
---@field icon? table
---@field lsp? table<string, string>
---@field has? string|string[]
---@field conds? table<number, function|boolean>
---@field vscode? boolean

---@class KeymapOpts : BaseMapping
---@field [2] string|function # The right-hand side of the mapping

---@class ToggleMap : BaseMapping
---@field name? string
---@field get fun(buf?: number): boolean
---@field set fun(state: boolean, buf?: number)
---@field icon? ToggleIconConfig
---@field color? ToggleColorConfig
---@field notify? boolean

---@class keymap.set.Opts : vim.keymap.set.Opts
---@field vscode boolean?

local wk_maps = {}
local did_setup = false
local deepcopy = vim.deepcopy

---------------------------------------------------------------
-- keymap validation
---@param mappings KeymapOpts
---@return boolean success
---------------------------------------------------------------
local function validate_keymap(mappings)
	if not mappings then
		return false
	end
	if
		type(mappings) ~= "table"
		or type(mappings[1]) ~= "string"
		or (type(mappings[2]) ~= "string" and type(mappings[2]) ~= "function")
	then
		return false
	end
	return true
end

---------------------------------------------------------------
-- Resolve single mapping or array of mappings to array
---@param mappings any
---@return table[]
---------------------------------------------------------------
local function resolve_mappings(mappings)
	if type(mappings) ~= "table" then
		return {}
	end
	-- Single mapping: has [1] as string, or has keys but no [1]
	if type(mappings[1]) == "string" or (mappings[1] == nil and next(mappings)) then
		return { mappings }
	end
	return mappings
end

---------------------------------------------------------------
-- Check if a mapping is a toggle mapping
---@param mapping ToggleMap
---@return boolean
---------------------------------------------------------------
local function is_toggle_mapping(mapping)
	return vim.is_callable(mapping.get) and vim.is_callable(mapping.set)
end

---------------------------------------------------------------
---@param mode KeymapMode|KeymapMode[] Mode or modes for the mapping
---@param lhs string Left-hand side of the mapping
---@param rhs string|function Right-hand side of the mapping
---@param opts? keymap.set.Opts Additional options for the mapping
---@return boolean success Whether the mapping was set successfully
---------------------------------------------------------------
function M.safe_keymap_set(mode, lhs, rhs, opts)
	opts = opts or {}
	if vim.g.vscode and opts.vscode ~= true then
		return false
	end
	opts.vscode = nil
	opts.silent = opts.silent ~= false
	local ok = pcall(vim.keymap.set, mode, lhs, rhs, opts)
	return ok
end

---------------------------------------------------------------
---@param mapping KeymapOpts
---------------------------------------------------------------
local function set_keymap(mapping)
	local lhs, rhs = mapping[1], mapping[2]
	local mode = (mapping.mode and Utils.fn.ensure_list(mapping.mode)) or { "n" }
	local opts = {
		desc = Utils.fn.ensure_string(mapping.desc, ""),
		buffer = mapping.buffer,
		silent = mapping.silent,
		remap = mapping.remap,
		expr = mapping.expr,
		vscode = mapping.vscode,
	}
	if M.safe_keymap_set(mode, lhs, rhs, opts) and mapping.icon then
		M.add_to_wk({
			{ lhs, mode = mode, icon = mapping.icon, desc = mapping.desc or "", buffer = mapping.buffer },
		})
	end
end

---------------------------------------------------------------
---@param mapping KeymapOpts
---------------------------------------------------------------
local function process_mapping(mapping)
	if not validate_keymap(mapping) then
		return
	end
	if mapping.conds then
		for _, condition in ipairs(Utils.fn.ensure_list(mapping.conds)) do
			if not Utils.fn.evaluate(condition) then
				return
			end
		end
	end
	if mapping.lsp or mapping.has then
		local filter = (type(mapping.lsp) == "table" and mapping.lsp) or {}
		Utils.lsp.on(filter, function(_, buf)
			local opts = Utils.lsp.map(mapping, buf)
			if opts then
				set_keymap(opts)
			end
		end)
		return
	end
	set_keymap(mapping)
end

---------------------------------------------------------------
--- Set keymap(s)
---@param mappings KeymapOpts|KeymapOpts[]|ToggleMap|ToggleMap[]
---------------------------------------------------------------
function M.set(mappings, opts)
	mappings = resolve_mappings(mappings)
	opts = opts or {}
	if #mappings == 0 then
		return
	end
	for _, map in ipairs(mappings) do
		local mapping = vim.tbl_deep_extend("force", {}, opts, map)
		if opts.conds and map.conds then
			mapping.conds = vim.list_extend(vim.list_slice(opts.conds or {}), map.conds)
		end
		if is_toggle_mapping(mapping) then
			mapping = M.toggle(mapping) or {}
		end
		process_mapping(mapping)
	end
end

---------------------------------------------------------------
---Create a toggle mapping
---@param mapping ToggleMap
---@return KeymapOpts?
---------------------------------------------------------------
function M.toggle(mapping)
	if type(mapping[1]) ~= "string" or (mapping.notify ~= false and type(mapping.name) ~= "string") then
		return nil
	end

	local ui = Utils.icons.ui
	local icons = {
		enabled = (mapping.icon and mapping.icon.enabled) or ui.enabled,
		disabled = (mapping.icon and mapping.icon.disabled) or ui.disabled,
	}
	local color = {
		enabled = (mapping.color and mapping.color.enabled) or "green",
		disabled = (mapping.color and mapping.color.disabled) or "yellow",
	}

	---@param buf? number
	local function get(buf)
		buf = Utils.fn.ensure_buf(buf)
		local ok, state = pcall(mapping.get, buf)
		if not ok then
			Utils.notify.error("Failed to get state:\n" .. tostring(state), { title = mapping.desc })
		end
		return state
	end

	---@param state boolean
	---@param buf? number
	local function set(state, buf)
		buf = Utils.fn.ensure_buf(buf)
		local ok, err = pcall(mapping.set, state, buf)
		if not ok then
			Utils.notify.error("Failed to set state:\n" .. tostring(err), { title = mapping.desc })
		end
	end

	---@param buf? number
	local function toggle(buf)
		buf = Utils.fn.ensure_buf(buf)
		set(get(buf), buf)
		if mapping.notify ~= false then
			local enabled = get(buf)
			Utils.notify[enabled and "info" or "warn"](
				string.format("%s **%s**", enabled and "Enabled" or "Disabled", mapping.name),
				{ title = mapping.desc, buffer = buf }
			)
		end
	end

	return {
		mapping[1],
		toggle,
		mode = mapping.mode or "n",
		desc = function()
			if type(mapping.desc) == "function" then
				return mapping.desc(get())
			end
			return mapping.desc or string.format("Toggle %s", mapping.name)
		end,
		icon = function()
			local enabled = get()
			return {
				icon = enabled and icons.enabled or icons.disabled,
				color = enabled and color.enabled or color.disabled,
			}
		end,
		buffer = mapping.buffer,
		lsp = mapping.lsp,
		has = mapping.has,
		conds = mapping.conds,
		expr = mapping.expr,
		silent = mapping.silent,
		remap = mapping.remap,
	}
end

local ABBREV_CONDS = {
	-- disable abbreviations in comments and strings
	lsp_keyword = function()
		local ts = Utils.treesitter
		return ts.is_active() and not ts.find_node({ "comment", "string" })
	end,
}

---------------------------------------------------------------
---Create multiple abbreviations with shared options
---@param abbrevs Abbrevs[]
---@param opts? AbbrevOpts
---------------------------------------------------------------
function M.abbrev(abbrevs, opts)
	if type(abbrevs) ~= "table" then
		return
	end
	for _, abbrev in ipairs(abbrevs) do
		local right = abbrev[1]
		local merged = vim.tbl_deep_extend("force", {}, opts or {}, abbrev[3] or {})
		local mode = merged.mode or "ia"
		local conds = Utils.fn.ensure_list(merged.conds)
		merged.mode, merged.conds, merged.expr = nil, nil, true

		for _, wrong in ipairs(Utils.fn.ensure_list(abbrev[2])) do
			if type(wrong) == "string" and type(right) == "string" then
				vim.keymap.set(mode, wrong, function()
					for _, condition in ipairs(conds) do
						if type(condition) == "string" then
							condition = ABBREV_CONDS[condition]
							if not condition then
								return wrong
							end
						end
						if not Utils.fn.evaluate(condition, true) then
							return wrong
						end
					end
					return right
				end, merged)
			end
		end
	end
end

---------------------------------------------------------------
---Delete keymap(s) - handles single or multiple
---@param mappings KeymapOpts|string[]|table[] Single mapping or array
---@param opts? table Shared options for all mappings
---------------------------------------------------------------
function M.del(mappings, opts)
	for _, map in ipairs(mappings or {}) do
		local mapping = type(map) == "string" and { [1] = map } or map
		mapping = vim.tbl_deep_extend("force", {}, opts or {}, mapping)
		if mapping.icon then
			M.hide_from_wk({ { mapping[1], mode = mapping.mode or "n", buffer = mapping.buffer } })
		end
		local modes = mapping.mode and Utils.fn.ensure_list(mapping.mode) or { "n" }
		local del_opts = mapping.buffer ~= nil and { buffer = mapping.buffer } or {}
		pcall(vim.keymap.del, modes, mapping[1], del_opts)
	end
end

---------------------------------------------------------------
---Add mappings to which-key without setting them
---@param mappings wk.Spec|wk.Spec[] # Which-key mapping definitions
---------------------------------------------------------------
function M.add_to_wk(mappings)
	if type(mappings) ~= "table" then
		return
	end
	if type(mappings[1]) ~= "table" then
		mappings = { mappings }
	end
	for _, map in ipairs(mappings) do
		if type(map) == "table" then
			table.insert(wk_maps, map)
		end
	end
	if did_setup then
		vim.api.nvim_exec_autocmds("User", { pattern = "KeymapSet" })
	end
end

---------------------------------------------------------------
-- Hide mappings in which-key window
---@param mappings wk.Spec|wk.Spec[] # Which-key mapping definitions
---------------------------------------------------------------
function M.hide_from_wk(mappings)
	if type(mappings) ~= "table" then
		return
	end

	for _, map in ipairs(mappings) do
		if type(map) == "string" then
			mappings[_] = { [1] = map, hidden = true }
		elseif type(map) == "table" then
			map.hidden = true
		end
	end

	M.add_to_wk(mappings)
end

---------------------------------------------------------------
---Apply which-key mappings if available
---------------------------------------------------------------
function M._apply_which_key()
	if #wk_maps == 0 or not Pack.is_loaded("which-key.nvim") then
		return
	end
	local maps = vim.deepcopy(wk_maps)
	wk_maps = {}
	require("which-key").add(maps)
end

M.setup = function()
	Pack.on_load("which-key.nvim", function()
		M._apply_which_key()
		did_setup = true

		vim.api.nvim_create_autocmd("User", {
			pattern = "KeymapSet",
			callback = M._apply_which_key,
		})
	end)
end

return M
