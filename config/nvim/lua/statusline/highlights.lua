local colors = require("statusline.colors")
local utils = require("statusline.utils")

local M = {}

M.mode_order = { "Normal", "Insert", "Visual", "Replace", "Command", "Terminal" }

local default_mode_colors = {
	Normal = { bg = "blue", fg = "bg_dark" },
	Insert = { bg = "green", fg = "bg_dark" },
	Visual = { bg = "purple", fg = "bg_dark" },
	Replace = { bg = "red", fg = "bg_dark" },
	Command = { bg = "orange", fg = "bg_dark" },
	Terminal = { bg = "cyan", fg = "bg_dark" },
}

function M.current_mode_name()
	local raw = vim.api.nvim_get_mode().mode
	return utils.mode_key[raw] or "Normal"
end

local static_cache = {}
local sep_cache = {}

local function sanitize(hex)
	hex = hex or "NONE"
	return (hex:gsub("#", ""):gsub("[^%w]", "_"))
end

---@param fg? string
---@param bg? string
---@param italic? boolean
---@return string group_name
function M.get_static_hl(fg, bg, italic)
	local key = (fg or "NONE") .. "|" .. (bg or "NONE") .. "|" .. (italic and "i" or "n")
	local existing = static_cache[key]
	if existing then
		return existing
	end

	local name = "Stl_" .. sanitize(fg) .. "_" .. sanitize(bg) .. (italic and "_i" or "")
	local hl = {}
	if fg and fg ~= "NONE" then
		hl.fg = fg
	end
	if bg and bg ~= "NONE" then
		hl.bg = bg
	end
	if italic then
		hl.italic = true
	end
	vim.api.nvim_set_hl(0, name, hl)
	static_cache[key] = name
	return name
end

---@param fg string|nil
---@return string group_name
function M.get_sep_hl(fg)
	local key = fg or "NONE"
	local existing = sep_cache[key]
	if existing then
		return existing
	end

	local name = "StlSep_" .. sanitize(fg)
	local hl = { bg = "NONE" }
	if fg and fg ~= "NONE" then
		hl.fg = fg
	end
	vim.api.nvim_set_hl(0, name, hl)
	sep_cache[key] = name
	return name
end

function M.clear_static_cache()
	static_cache = {}
	sep_cache = {}
end

function M.setup_mode_highlights()
	for _, name in ipairs(M.mode_order) do
		local group = "StatuslineMode" .. name
		local ok, existing = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
		local user_defined = ok and existing and (existing.fg or existing.bg)
		local d = default_mode_colors[name]

		if not user_defined then
			local bg = colors.resolve(d.bg)
			local fg = colors.resolve(d.fg)
			local hl = {}
			if fg then
				hl.fg = fg
			end
			if bg then
				hl.bg = bg
			end
			vim.api.nvim_set_hl(0, group, hl)
		end

		local resolved = vim.api.nvim_get_hl(0, { name = group, link = false })
		local bg_hex = resolved.bg and string.format("#%06x", resolved.bg) or colors.resolve(d.bg)
		local sep_hl = { bg = "NONE" }
		if bg_hex then
			sep_hl.fg = bg_hex
		end
		vim.api.nvim_set_hl(0, group .. "Sep", sep_hl)
	end
end

---@return string hl_group
---@return string sep_hl_group
function M.get_dynamic_hl()
	local name = M.current_mode_name()
	return "StatuslineMode" .. name, "StatuslineMode" .. name .. "Sep"
end

return M
