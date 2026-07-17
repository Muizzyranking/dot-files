local M = {}

local fg_groups = {
	red = { "DiagnosticError", "Error" },
	green = { "String", "GitSignsAdd" },
	orange = { "DiagnosticWarn" },
	blue = { "Function", "DiagnosticInfo" },
	purple = { "Constant" },
	cyan = { "Special", "DiagnosticHint" },

	fg = { "Normal" },
	fg_bright = { "Normal" },
	fg_dim = { "Comment" },
	fg_dimmer = { "LineNr" },
	bg_dark = { "Search", "IncSearch", "CurSearch", "PmenuSel", "Todo" },
}

local bg_groups = {
	bg = { "Normal" },
	bg_alt = { "CursorLine", "ColorColumn" },
	surface = { "CursorLine", "ColorColumn" },
	surface_light = { "Visual" },
}

local hl_cache = {}

function M.clear_cache()
	hl_cache = {}
end

---@param group string
---@param kind "fg"|"bg"
---@return string|nil
local function extract(group, kind)
	local key = kind .. ":" .. group
	if hl_cache[key] ~= nil then
		local cached = hl_cache[key]
		return cached ~= false and cached or nil
	end

	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
	local hex = nil
	if ok and hl and hl[kind] then
		hex = string.format("#%06x", hl[kind])
	end

	hl_cache[key] = hex or false
	return hex
end

---@param groups string[]
---@param kind "fg"|"bg"
---@return string|nil
local function extract_first(groups, kind)
	for _, group in ipairs(groups) do
		local hex = extract(group, kind)
		if hex then
			return hex
		end
	end
	return nil
end

---@param group string
---@param kind "fg"|"bg"
---@return string|nil
function M.group_color(group, kind)
	return extract(group, kind)
end

---@param value string|nil
---@param fallback string|nil
---@return string|nil
function M.resolve(value, fallback)
	if value == nil then
		if fallback == nil then
			return nil
		end
		return M.resolve(fallback, nil)
	end

	if value == "NONE" or value == "none" then
		return "NONE"
	end

	if value:sub(1, 1) == "#" then
		return value
	end

	if bg_groups[value] then
		local hex = extract_first(bg_groups[value], "bg")
		if hex then
			return hex
		end
	end

	if fg_groups[value] then
		local hex = extract_first(fg_groups[value], "fg")
		if hex then
			return hex
		end
	end

	local literal = extract(value, "fg")
	if literal then
		return literal
	end

	if fallback ~= nil then
		return M.resolve(fallback, nil)
	end
	return nil
end

return M
