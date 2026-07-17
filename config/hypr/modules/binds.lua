local mainMod = "SUPER"

local function layout_action(actions)
	return function()
		local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
		if not workspace then
			return
		end

		local layout = workspace.tiled_layout
		local action = actions[layout] or actions.default

		if action then
			hl.dispatch(action)
		end
	end
end

local function copy(t)
	local u = {}
	for k, v in pairs(t) do
		u[k] = v
	end
	return u
end

local binds = {
	-- Apps
	{ "Return", cmd = TERMINAL },
	{ "E", cmd = FILEMANAGER },
	{ "B", cmd = BROWSER },

	-- Window management
	{ "Q", action = hl.dsp.window.close(), description = "Window: Close" },
	{
		"F",
		action = layout_action({
			scrolling = hl.dsp.layout("colresize +conf"),
			default = hl.dsp.window.float({ action = "toggle" }),
		}),
	},
	{
		"F",
		sMod = true,
		action = hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	},

	-- Focus directions
	{ "Left", action = hl.dsp.focus({ direction = "l" }) },
	{ "Right", action = hl.dsp.focus({ direction = "r" }) },
	{ "Up", action = hl.dsp.focus({ direction = "u" }) },
	{ "Down", action = hl.dsp.focus({ direction = "d" }) },
	{ "H", action = hl.dsp.focus({ direction = "l" }) },
	{ "L", action = hl.dsp.focus({ direction = "r" }) },
	{ "K", action = hl.dsp.focus({ direction = "u" }) },
	{ "J", action = hl.dsp.focus({ direction = "d" }) },

	-- Move directions
	{ "Left", sMod = true, action = hl.dsp.window.move({ direction = "l" }) },
	{ "Right", sMod = true, action = hl.dsp.window.move({ direction = "r" }) },
	{ "Up", sMod = true, action = hl.dsp.window.move({ direction = "u" }) },
	{ "Down", sMod = true, action = hl.dsp.window.move({ direction = "d" }) },
	{ "H", sMod = true, action = hl.dsp.window.move({ direction = "l" }) },
	{ "L", sMod = true, action = hl.dsp.window.move({ direction = "r" }) },
	{ "K", sMod = true, action = hl.dsp.window.move({ direction = "u" }) },
	{ "J", sMod = true, action = hl.dsp.window.move({ direction = "d" }) },

	-- First/last window
	{ "Home", action = hl.dsp.focus({ window = "first" }) },
	{ "End", action = hl.dsp.focus({ window = "last" }) },

	-- Center window
	{ "C", sMod = true, action = hl.dsp.window.center() },

	-- Workspace focus
	{ "1", action = hl.dsp.focus({ workspace = 1 }) },
	{ "2", action = hl.dsp.focus({ workspace = 2 }) },
	{ "3", action = hl.dsp.focus({ workspace = 3 }) },
	{ "4", action = hl.dsp.focus({ workspace = 4 }) },
	{ "5", action = hl.dsp.focus({ workspace = 5 }) },
	{ "6", action = hl.dsp.focus({ workspace = 6 }) },
	{ "7", action = hl.dsp.focus({ workspace = 7 }) },
	{ "8", action = hl.dsp.focus({ workspace = 8 }) },
	{ "9", action = hl.dsp.focus({ workspace = 9 }) },
	{ "0", action = hl.dsp.focus({ workspace = 10 }) },

	-- Workspace move
	{ "1", sMod = true, action = hl.dsp.window.move({ workspace = 1 }) },
	{ "2", sMod = true, action = hl.dsp.window.move({ workspace = 2 }) },
	{ "3", sMod = true, action = hl.dsp.window.move({ workspace = 3 }) },
	{ "4", sMod = true, action = hl.dsp.window.move({ workspace = 4 }) },
	{ "5", sMod = true, action = hl.dsp.window.move({ workspace = 5 }) },
	{ "6", sMod = true, action = hl.dsp.window.move({ workspace = 6 }) },
	{ "7", sMod = true, action = hl.dsp.window.move({ workspace = 7 }) },
	{ "8", sMod = true, action = hl.dsp.window.move({ workspace = 8 }) },
	{ "9", sMod = true, action = hl.dsp.window.move({ workspace = 9 }) },
	{ "0", sMod = true, action = hl.dsp.window.move({ workspace = 10 }) },

	-- Scroll workspaces
	{ "mouse_down", action = hl.dsp.focus({ workspace = "e-1" }) },
	{ "mouse_up", action = hl.dsp.focus({ workspace = "e+1" }) },

	-- Page Up/Down workspace navigation
	{ "Page_Down", action = hl.dsp.focus({ workspace = "e+1" }) },
	{ "Page_Up", action = hl.dsp.focus({ workspace = "e-1" }) },
	{ "U", action = hl.dsp.focus({ workspace = "e-1" }) },
	{ "I", action = hl.dsp.focus({ workspace = "e+1" }) },

	-- Move to adjacent workspace (mod + CTRL)
	{ "Down", ctrl = true, action = hl.dsp.window.move({ workspace = "e+1" }) },
	{ "Up", ctrl = true, action = hl.dsp.window.move({ workspace = "e-1" }) },
	{ "U", ctrl = true, action = hl.dsp.window.move({ workspace = "e-1" }) },
	{ "I", ctrl = true, action = hl.dsp.window.move({ workspace = "e+1" }) },

	-- Special workspace
	{ "S", action = hl.dsp.workspace.toggle_special("magic") },
	{ "S", sMod = true, action = hl.dsp.window.move({ workspace = "special:magic" }) },

	-- Mouse binds
	{ "mouse:272", action = hl.dsp.window.drag(), mouse = true },
	{ "mouse:273", action = hl.dsp.window.resize(), mouse = true },

	-- Resize submap
	{ "R", sMod = true, action = hl.dsp.submap("resize") },

	-- Quick resize
	{ "Minus", action = hl.dsp.window.resize({ x = -20, y = 0, relative = true }), repeating = true },
	{ "Equal", action = hl.dsp.window.resize({ x = 20, y = 0, relative = true }), repeating = true },

	-- Screenshots
	{ "Print", mod = false, cmd = "dms screenshot" },
	{ "Print", mod = false, ctrl = true, cmd = "dms screenshot full" },
	{ "Print", mod = false, alt = true, cmd = "dms screenshot window" },

	-- DMS IPC calls
	{ "DELETE", dms = "powermenu toggle" },
	{ "SPACE", dms = "spotlight toggle" },
	{ "SPACE", alt = true, mod = false, dms = "spotlight-bar toggle" },
	{ "V", dms = "clipboard toggle" },
	{ "M", dms = "processlist focusOrToggle" },
	{ "comma", dms = "settings focusOrToggle" },
	{ "N", dms = "notifications toggle" },
	{ "N", sMod = true, dms = "notepad toggle" },
	{ "L", alt = true, dms = "lock lock" },
	{ "Delete", mod = false, ctrl = true, alt = true, cmd = "dms ipc call processlist focusOrToggle" },

	-- Volume
	{ "XF86AudioRaiseVolume", mod = false, dms = "audio increment 3", locked = true, repeating = true },
	{ "XF86AudioLowerVolume", mod = false, dms = "audio decrement 3", locked = true, repeating = true },
	{ "XF86AudioMute", mod = false, dms = "audio mute", locked = true },

	-- Media controls
	{ "XF86AudioPlay", mod = false, cmd = "playerctl play-pause", locked = true },
	{ "XF86AudioPrev", mod = false, cmd = "playerctl previous", locked = true },
	{ "XF86AudioNext", mod = false, cmd = "playerctl next", locked = true },

	-- Brightness
	{
		"XF86MonBrightnessUp",
		mod = false,
		cmd = 'dms ipc call brightness increment 5 ""',
		locked = true,
		repeating = true,
	},
	{
		"XF86MonBrightnessDown",
		mod = false,
		cmd = 'dms ipc call brightness decrement 5 ""',
		locked = true,
		repeating = true,
	},

	-- Hypremoji
	{ "period", cmd = "plasma-emojier" },
}

for _, b in ipairs(binds) do
	local key = b[1]
	local parts = {}

	if b.mod ~= false then
		if b.sMod == true then
			table.insert(parts, mainMod .. " + SHIFT")
		else
			table.insert(parts, mainMod)
		end
	end

	if b.ctrl == true then
		table.insert(parts, "CTRL")
	end
	if b.alt == true then
		table.insert(parts, "ALT")
	end

	table.insert(parts, key)

	local keyStr = table.concat(parts, " + ")

	-- Resolve action: dms > cmd > action
	local action
	if b.dms then
		action = hl.dsp.exec_cmd("dms ipc call " .. b.dms)
	elseif b.cmd then
		action = hl.dsp.exec_cmd(b.cmd)
	else
		action = b.action
	end

	local opts = b.opts and copy(b.opts) or {}

	if b.description ~= nil then
		opts.description = b.description
	end
	if b.mouse == true then
		opts.mouse = true
	end
	if b.repeating == true then
		opts.repeating = true
	end
	if b.locked == true then
		opts.locked = true
	end

	hl.bind(keyStr, action, opts)
end

hl.define_submap("resize", function()
	hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
	hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
	hl.bind("escape", hl.dsp.submap("reset"))
end)
