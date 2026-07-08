local mainMod = "SUPER"
local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"

local function mod(key)
	return mainMod .. " + " .. key
end

-- local function sMod(key)
-- 	return mod("SHIFT + " .. key)
-- end
--
-- function bind(key, ...)
-- 	hl.bind(mod(key), ...)
-- end

-- apps
hl.bind(mod("Return"), hl.dsp.exec_cmd(TERMINAL))
hl.bind(mod("E"), hl.dsp.exec_cmd(FILEMANAGER))
hl.bind(mod("B"), hl.dsp.exec_cmd(BROWSER))

-- hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod("Q"), hl.dsp.window.close(), { description = "Window: Close" })
hl.bind(mod("F"), hl.dsp.layout("colresize +conf"))

local directions = {
	{ key = "Left", dir = "l" },
	{ key = "Right", dir = "r" },
	{ key = "Up", dir = "u" },
	{ key = "Down", dir = "d" },
	{ key = "H", dir = "l" },
	{ key = "L", dir = "r" },
	{ key = "K", dir = "u" },
	{ key = "J", dir = "d" },
}

for _, d in ipairs(directions) do
	hl.bind(mod(d.key), hl.dsp.focus({ direction = d.dir }))
	hl.bind(mod("SHIFT + " .. d.key), hl.dsp.window.move({ direction = d.dir }))
end

hl.bind(mod("Home"), hl.dsp.focus({ window = "first" }))
hl.bind(mod("End"), hl.dsp.focus({ window = "last" }))

-- Center window
hl.bind(mod("SHIFT + C"), hl.dsp.window.center())

for i = 1, 10 do
	local key = i == 10 and "0" or tostring(i)
	hl.bind(mod(key), hl.dsp.focus({ workspace = i }))
	hl.bind(mod("SHIFT + " .. key), hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces
hl.bind(mod("mouse_down"), hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod("mouse_up"), hl.dsp.focus({ workspace = "e+1" }))

-- Page Up/Down workspace navigation
hl.bind(mod("Page_Down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod("Page_Up"), hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod("U"), hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod("I"), hl.dsp.focus({ workspace = "e+1" }))

-- Move to adjacent workspace
hl.bind(mod("CTRL + Down"), hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mod("CTRL + Up"), hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mod("CTRL + U"), hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mod("CTRL + I"), hl.dsp.window.move({ workspace = "e+1" }))

hl.bind(mod("S"), hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod("SHIFT + S"), hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mod("mouse:272"), hl.dsp.window.drag(), { mouse = true })
hl.bind(mod("mouse:273"), hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + SHIFT + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
	hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
	hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
	hl.bind("escape", hl.dsp.submap("reset"))
end)

hl.bind(mod("Minus"), hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mod("Equal"), hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })

hl.bind("Print", hl.dsp.exec_cmd("dms screenshot"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("dms screenshot full"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("dms screenshot window"))

hl.bind(mod("DELETE"), hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
hl.bind(mod("space"), hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind(mod("V"), hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind(mod("M"), hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))
hl.bind(mod("comma"), hl.dsp.exec_cmd("dms ipc call settings focusOrToggle"))
hl.bind(mod("N"), hl.dsp.exec_cmd("dms ipc call notifications toggle"))
hl.bind(mod("SHIFT + N"), hl.dsp.exec_cmd("dms ipc call notepad toggle"))
hl.bind(mod("ALT + L"), hl.dsp.exec_cmd("dms ipc call lock lock"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"))

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scripts .. "/volume.sh --inc"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scripts .. "/volume.sh --dec"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scripts .. "/volume.sh --toggle"), { locked = true })

-- Media controls
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })

-- Brightness
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd('dms ipc call brightness increment 5 ""'),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd('dms ipc call brightness decrement 5 ""'),
	{ locked = true, repeating = true }
)

hl.bind(mod("period"), hl.dsp.exec_cmd("hypremoji"))
