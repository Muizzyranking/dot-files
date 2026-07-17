local Component = require("statusline.component")

local M = {}

M.layout = { left = {}, center = {}, right = {} }
M.ft = {}

local prepared_components = {}

---@param comp Statusline.Component
local function prepare_component(comp)
	comp:reresolve()

	if not comp._registered then
		comp._registered = true
		table.insert(prepared_components, comp)
	end

	return comp
end

---@param layout { left?: Statusline.Component[], center?: Statusline.Component[], right?: Statusline.Component[] }
local function prepare_layout(layout)
	for _, section in ipairs({ "left", "center", "right" }) do
		for _, comp in ipairs(layout[section] or {}) do
			prepare_component(comp)
		end
	end
	return layout
end

---@param opts { fg?: string, bg?: string, padding?: string, spacing?: string, layout?: table, ft?: table<string, table>, disable_ft?: string[] }
function M.setup(opts)
	opts = opts or {}

	if opts.fg then
		Component.defaults.fg = opts.fg
	end
	if opts.bg then
		Component.defaults.bg = opts.bg
	end
	if opts.padding ~= nil then
		Component.defaults.padding = opts.padding
	end
	if opts.spacing ~= nil then
		Component.defaults.spacing = opts.spacing
	end

	if opts.disable_ft then
		Component.defaults.disabled_ft = Component.defaults.disabled_ft or {}
		for _, ft in ipairs(opts.disable_ft) do
			Component.defaults.disabled_ft[ft] = true
		end
	end

	M.layout = prepare_layout(opts.layout or M.layout)

	M.ft = {}
	for ft, layout in pairs(opts.ft or {}) do
		M.ft[ft] = prepare_layout(layout)
	end
end

function M.get_default(opts)
	return Component.defaults[opts]
end

---@return table layout
function M.get_layout(ft)
	return M.ft[ft] or M.layout
end

function M.reresolve_all()
	for _, comp in ipairs(prepared_components) do
		comp:reresolve()
	end
end

return M
