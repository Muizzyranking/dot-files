local M = {}

local mainMod = "SUPER"

---@alias Dispatcher HL.Dispatcher

---@class Bind
---@field [1] string            Key name
---@field mod? boolean          Include SUPER. Default true; set false to omit
---@field shift? boolean        Include SHIFT
---@field ctrl? boolean         Include CTRL
---@field alt? boolean          Include ALT
---@field action? Dispatcher    Hyprland dispatcher or function
---@field cmd? string           Shell command (wrapped in hl.dsp.exec_cmd)
---@field dms? string           DMS IPC call (wrapped in `dms ipc call`)
---@field description? string   Description
---@field mouse? boolean        Mouse bind
---@field repeating? boolean    Repeat while held
---@field locked? boolean       Works while the screen is locked
---@field opts? table           Extra raw options passed to hl.bind

local OPT_FIELDS = { "description", "mouse", "repeating", "locked" }

--- Get the nth monitor, ordered left to right (1 = leftmost).
--- Resolved at keypress time so hotplugging works without a reload.
---@param n integer
---@return HL.Monitor|nil
local function get_monitor(n)
	local mons = {}
	for _, m in ipairs(hl.get_monitors()) do
		table.insert(mons, m)
	end
	table.sort(mons, function(a, b)
		return a.x < b.x
	end)
	return mons[n]
end

---@param n integer
---@param make_dsp fun(name: string): Dispatcher
---@return fun()
function M.on_monitor(n, make_dsp)
	return function()
		local m = get_monitor(n)
		if m then
			hl.dispatch(make_dsp(m.name))
		end
	end
end

---@param actions table<string, Dispatcher>
---@return Dispatcher?
function M.layout_action(actions)
	local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
	if not workspace then
		return nil
	end
	return actions[workspace.tiled_layout] or actions.default
end

---@param b Bind
---@return string
local function key_string(b)
	local parts = {}
	if b.mod ~= false then
		table.insert(parts, mainMod)
	end
	if b.shift then
		table.insert(parts, "SHIFT")
	end
	if b.ctrl then
		table.insert(parts, "CTRL")
	end
	if b.alt then
		table.insert(parts, "ALT")
	end
	table.insert(parts, b[1])
	return table.concat(parts, " + ")
end

---@param b Bind
---@return Dispatcher
local function resolve_action(b)
	if b.dms then
		return hl.dsp.exec_cmd("dms ipc call " .. b.dms)
	elseif b.cmd then
		return hl.dsp.exec_cmd(b.cmd)
	end
	return b.action
end

---@param b Bind
---@return table
local function build_opts(b)
	local opts = {}
	for k, v in pairs(b.opts or {}) do
		opts[k] = v
	end
	for _, field in ipairs(OPT_FIELDS) do
		if b[field] ~= nil then
			opts[field] = b[field]
		end
	end
	return opts
end

function M.register(binds)
	for _, b in ipairs(binds) do
		hl.bind(key_string(b), resolve_action(b), build_opts(b))
	end
end

return M
