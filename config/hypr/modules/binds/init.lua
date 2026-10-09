local h = require("modules.binds.helpers")

---@type Bind[]
local binds = {
	-- Apps
	{ "Return", cmd = TERMINAL, description = "App: Terminal" },
	{ "E", cmd = FILEMANAGER, description = "App: File manager" },
	{ "B", cmd = BROWSER, description = "App: Browser" },
	{ "period", cmd = "plasma-emojier", description = "App: Emoji picker" },

	-- Window management
	{ "Q", action = hl.dsp.window.close(), description = "Window: Close" },
	{
		"F",
		action = h.layout_action({
			scrolling = hl.dsp.layout("colresize +conf"),
			default = hl.dsp.window.float({ action = "toggle" }),
		}),
		description = "Window: Toggle float (scrolling layout: cycle column width)",
	},
	{
		"F",
		shift = true,
		action = hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
		description = "Window: Toggle fullscreen",
	},
	{
		"F12",
		mod = false,
		action = hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
		description = "Window: Toggle fullscreen",
	},
	{ "C", shift = true, action = hl.dsp.window.center(), description = "Window: Center" },

	-- Workspace navigation
	{ "mouse_up", action = hl.dsp.focus({ workspace = "e-1" }), description = "Workspace: Next (scroll)" },
	{ "mouse_down", action = hl.dsp.focus({ workspace = "e+1" }), description = "Workspace: Previous (scroll)" },
	{ "Page_Up", action = hl.dsp.focus({ workspace = "e-1" }), description = "Workspace: Previous" },
	{ "Page_Down", action = hl.dsp.focus({ workspace = "e+1" }), description = "Workspace: Next" },
	{ "U", action = hl.dsp.focus({ workspace = "e-1" }), description = "Workspace: Previous" },
	{ "I", action = hl.dsp.focus({ workspace = "e+1" }), description = "Workspace: Next" },

	-- Move window to adjacent workspace
	{
		"Up",
		ctrl = true,
		action = hl.dsp.window.move({ workspace = "e-1" }),
		description = "Window: Move to previous workspace",
	},
	{
		"Down",
		ctrl = true,
		action = hl.dsp.window.move({ workspace = "e+1" }),
		description = "Window: Move to next workspace",
	},
	{
		"U",
		ctrl = true,
		action = hl.dsp.window.move({ workspace = "e-1" }),
		description = "Window: Move to previous workspace",
	},
	{
		"I",
		ctrl = true,
		action = hl.dsp.window.move({ workspace = "e+1" }),
		description = "Window: Move to next workspace",
	},

	-- Special workspace
	{ "S", action = hl.dsp.workspace.toggle_special("magic"), description = "Special: Toggle scratchpad" },
	{
		"S",
		shift = true,
		action = hl.dsp.window.move({ workspace = "special:magic" }),
		description = "Special: Move window to scratchpad",
	},

	-- Mouse
	{ "mouse:272", action = hl.dsp.window.drag(), mouse = true, description = "Mouse: Drag window" },
	{ "mouse:273", action = hl.dsp.window.resize(), mouse = true, description = "Mouse: Resize window" },

	-- Resize
	{ "R", shift = true, action = hl.dsp.submap("resize"), description = "Resize: Enter submap" },
	{
		"Minus",
		action = hl.dsp.window.resize({ x = -20, y = 0, relative = true }),
		repeating = true,
		description = "Resize: Narrower",
	},
	{
		"Equal",
		action = hl.dsp.window.resize({ x = 20, y = 0, relative = true }),
		repeating = true,
		description = "Resize: Wider",
	},

	-- Screenshots
	{ "Print", mod = false, cmd = "dms screenshot", description = "Screenshot: Region" },
	{ "Print", mod = false, ctrl = true, cmd = "dms screenshot full", description = "Screenshot: Full screen" },
	{ "Print", mod = false, alt = true, cmd = "dms screenshot window", description = "Screenshot: Window" },

	-- DMS IPC
	{ "DELETE", dms = "powermenu toggle", description = "DMS: Power menu" },
	{ "SPACE", dms = "spotlight toggle", description = "DMS: Spotlight" },
	{ "SPACE", mod = false, alt = true, dms = "spotlight-bar toggle", description = "DMS: Spotlight bar" },
	{ "V", dms = "clipboard toggle", description = "DMS: Clipboard history" },
	{ "M", dms = "processlist focusOrToggle", description = "DMS: Process list" },
	{ "comma", dms = "settings focusOrToggle", description = "DMS: Settings" },
	{ "N", dms = "notifications toggle", description = "DMS: Notifications" },
	{ "N", shift = true, dms = "notepad toggle", description = "DMS: Notepad" },
	{ "L", alt = true, dms = "lock lock", description = "DMS: Lock screen" },
	{
		"Delete",
		mod = false,
		ctrl = true,
		alt = true,
		dms = "processlist focusOrToggle",
		description = "DMS: Process list",
	},

	-- Volume
	{
		"XF86AudioRaiseVolume",
		mod = false,
		dms = "audio increment 3",
		locked = true,
		repeating = true,
		description = "Audio: Volume up",
	},
	{
		"XF86AudioLowerVolume",
		mod = false,
		dms = "audio decrement 3",
		locked = true,
		repeating = true,
		description = "Audio: Volume down",
	},
	{ "XF86AudioMute", mod = false, dms = "audio mute", locked = true, description = "Audio: Mute" },
	{ "XF86AudioMicMute", mod = false, dms = "audio micmute", locked = true, description = "Audio: Mute" },

	-- Media
	{
		"XF86AudioPlay",
		mod = false,
		cmd = "playerctl play-pause",
		locked = true,
		description = "Media: Play/pause",
	},
	{ "XF86AudioPrev", mod = false, cmd = "playerctl previous", locked = true, description = "Media: Previous" },
	{ "XF86AudioNext", mod = false, cmd = "playerctl next", locked = true, description = "Media: Next" },

	-- Brightness
	{
		"XF86MonBrightnessUp",
		mod = false,
		dms = 'brightness increment 5 ""',
		locked = true,
		repeating = true,
		description = "Brightness: Up",
	},
	{
		"XF86MonBrightnessDown",
		mod = false,
		dms = 'brightness decrement 5 ""',
		locked = true,
		repeating = true,
		description = "Brightness: Down",
	},
}

--- Focus / move window by direction (arrows + vim keys)
---@type { dir: string, name: string, keys: string[] }[]
local directions = {
	{ dir = "l", name = "left", keys = { "Left", "H" } },
	{ dir = "r", name = "right", keys = { "Right", "L" } },
	{ dir = "u", name = "up", keys = { "Up", "K" } },
	{ dir = "d", name = "down", keys = { "Down", "J" } },
}

for _, d in ipairs(directions) do
	for _, key in ipairs(d.keys) do
		table.insert(binds, {
			key,
			action = hl.dsp.focus({ direction = d.dir }),
			description = "Focus: " .. d.name,
		})
		table.insert(binds, {
			key,
			shift = true,
			action = hl.dsp.window.move({ direction = d.dir }),
			description = "Window: Move " .. d.name,
		})
	end
end

for n = 1, 4 do
	local key = tostring(n)
	table.insert(binds, {
		key,
		alt = true,
		action = h.on_monitor(n, function(name)
			return hl.dsp.focus({ monitor = name })
		end),
		description = "Monitor: Go to " .. n,
	})
	table.insert(binds, {
		key,
		ctrl = true,
		action = h.on_monitor(n, function(name)
			return hl.dsp.workspace.move({ monitor = name })
		end),
		description = "Monitor: Move workspace to " .. n,
	})
end

for n = 1, 10 do
	local key = tostring(n % 10)
	table.insert(binds, {
		key,
		action = hl.dsp.focus({ workspace = n }),
		description = "Workspace: Focus " .. n,
	})
	table.insert(binds, {
		key,
		shift = true,
		action = hl.dsp.window.move({ workspace = n }),
		description = "Workspace: Move window to " .. n,
	})
end

---@type { key: string, x: integer, y: integer }[]
local resize_steps = {
	{ key = "right", x = 10, y = 0 },
	{ key = "left", x = -10, y = 0 },
	{ key = "up", x = 0, y = -10 },
	{ key = "down", x = 0, y = 10 },
}

hl.define_submap("resize", function()
	for _, s in ipairs(resize_steps) do
		hl.bind(s.key, hl.dsp.window.resize({ x = s.x, y = s.y, relative = true }), {
			repeating = true,
			description = "Resize: " .. s.key,
		})
	end
	hl.bind("escape", hl.dsp.submap("reset"), { description = "Resize: Exit submap" })
end)

h.register(binds)
