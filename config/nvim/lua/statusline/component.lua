local colors = require("statusline.colors")
local highlights = require("statusline.highlights")

---@class Statusline.Component
---@field value string|fun():(string|table[])
---@field hl? string|table|fun():table|nil
---@field sep? { left?: string, right?: string }|nil
---@field cond? fun():boolean|nil
---@field padding? string
---@field spacing? integer
---@field [any] any
local Component = {}
Component.__index = Component

Component.defaults = {
	fg = "fg",
	bg = "NONE",
	padding = " ",
	spacing = "",
	disabled_ft = {},
}

---@param hl string|table|function|nil
---@return boolean
local function needs_render_time_resolution(hl)
	if type(hl) == "function" then
		return true
	end
	if type(hl) == "table" then
		return type(hl.fg) == "function" or type(hl.bg) == "function"
	end
	return false
end

function Component:_classify_hl()
	local hl = self.hl

	if type(hl) == "table" and hl.dynamic then
		self._kind = "dynamic"
	elseif needs_render_time_resolution(hl) then
		self._kind = "fn"
		if type(hl) == "function" then
			self._hl_fn = hl
		else
			local fg_field, bg_field = hl.fg, hl.bg
			self._hl_fn = function()
				return {
					fg = type(fg_field) == "function" and fg_field() or fg_field,
					bg = type(bg_field) == "function" and bg_field() or bg_field,
				}
			end
		end
	else
		self._kind = "static"
	end
end

function Component:reresolve()
	if self._kind ~= "static" then
		return
	end

	local hl = self.hl
	local fg = colors.resolve(type(hl) == "string" and hl or (hl and hl.fg), Component.defaults.fg)
	local bg = colors.resolve(type(hl) == "table" and hl.bg or nil, Component.defaults.bg)
	local italic = type(hl) == "table" and hl.italic or false

	self._fg, self._bg, self._italic = fg, bg, italic
	self._hl_group = highlights.get_static_hl(fg, bg, italic)
	self._sep_hl_group = highlights.get_sep_hl(bg)
end

---@return string hl_group
---@return string sep_hl_group
---@return string|nil bg_hex
---@return string|nil fg_hex
function Component:resolve()
	if self._kind == "static" then
		if not self._hl_group then
			self:reresolve()
		end
		return self._hl_group, self._sep_hl_group, self._bg, self._fg
	elseif self._kind == "dynamic" then
		local hl_group, sep_hl_group = highlights.get_dynamic_hl()
		local bg = colors.group_color(hl_group, "bg")
		local fg = colors.group_color(hl_group, "fg")
		return hl_group, sep_hl_group, bg, fg
	else
		local result = self._hl_fn() or {}
		local fg = colors.resolve(result.fg, Component.defaults.fg)
		local bg = colors.resolve(result.bg, Component.defaults.bg)
		local italic = result.italic or false
		local hl_group = highlights.get_static_hl(fg, bg, italic)
		local sep_hl_group = highlights.get_sep_hl(bg)
		return hl_group, sep_hl_group, bg, fg
	end
end

---@param opts Statusline.Component
---@return Statusline.Component
function Component.new(opts)
	local self = setmetatable({}, Component)
	self.value = opts.value
	self.cond = opts.cond
	self.sep = opts.sep
	self.padding = opts.padding or " "
	self.spacing = opts.spacing or 0
	self.hl = opts.hl
	self:_classify_hl()
	return self
end

return Component
