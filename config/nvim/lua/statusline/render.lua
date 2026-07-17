local Component = require("statusline.component")
local colors = require("statusline.colors")
local highlights = require("statusline.highlights")
local config = require("statusline.config")
local utils = require("statusline.utils")

local M = {}

---@param hl_group string
---@param text string
---@return string
local function wrap(hl_group, text)
	return "%#" .. hl_group .. "#" .. text .. "%*"
end

---@param segments { text: string, hl?: string }[]
---@param hl_group string
---@param bg string|nil
---@param fallback_fg string|nil
---@param padding string
---@param spacing integer
---@return string
local function render_segments(segments, hl_group, bg, fallback_fg, padding, spacing)
	local gap = string.rep(" ", spacing or 0)
	local filler = gap ~= "" and wrap(hl_group, gap) or ""

	local pieces = {}
	for _, seg in ipairs(segments) do
		local seg_fg = seg.hl and colors.resolve(seg.hl, fallback_fg) or fallback_fg
		local seg_group = highlights.get_static_hl(seg_fg, bg)
		pieces[#pieces + 1] = wrap(seg_group, seg.text)
	end

	return wrap(hl_group, padding) .. table.concat(pieces, filler) .. wrap(hl_group, padding)
end

---@param comp Statusline.Component
---@param is_first boolean
---@param is_last boolean
---@param section "left"|"center"|"right"
---@return string
local function render_component(comp, is_first, is_last, section)
	if comp.cond and not comp.cond() then
		return ""
	end

	local val = comp.value
	if type(val) == "function" then
		val = val()
	end

	local is_segments = type(val) == "table"
	if is_segments then
		if #val == 0 then
			return ""
		end
	else
		if val == nil or val == "" then
			return ""
		end
	end

	local hl_group, sep_hl_group, bg, fg = comp:resolve()
	local padding = comp.padding or Component.defaults.padding

	local body
	if is_segments then
		body = render_segments(val, hl_group, bg, fg, padding, comp.spacing)
	else
		body = wrap(hl_group, padding .. val .. padding)
	end

	local left_sep, right_sep = "", ""
	if comp.sep then
		if comp.sep.left and not (section == "left" and is_first) then
			left_sep = wrap(sep_hl_group, comp.sep.left)
		end
		if comp.sep.right and not (section == "right" and is_last) then
			right_sep = wrap(sep_hl_group, comp.sep.right)
		end
	end

	return left_sep .. body .. right_sep
end

---@param components Statusline.Component[]
---@param section "left"|"center"|"right"
---@return string
local function render_section(components, section)
	local parts = {}
	local n = #components
	for i, comp in ipairs(components) do
		local piece = render_component(comp, i == 1, i == n, section)
		if piece ~= "" then
			parts[#parts + 1] = piece
		end
	end
	return table.concat(parts, Component.defaults.spacing)
end

---@return string
function M.render()
	local buf = utils.stbuf()
	local ft = vim.bo[buf].filetype
	local hidden_ft = Component.defaults.disabled_ft
	if hidden_ft[ft] then
		return ""
	end
	local layout = config.get_layout(ft)
	local left = render_section(layout.left or {}, "left")
	local center = render_section(layout.center or {}, "center")
	local right = render_section(layout.right or {}, "right")
	return left .. "%=" .. center .. "%=" .. right
end

return M
