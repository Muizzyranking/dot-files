local colors = require("utils.colors")

local function rgb(h)
	h = h:gsub("#", "")
	return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
end

local function mix(a, b, t)
	local ar, ag, ab = rgb(a)
	local br, bg, bb = rgb(b)
	local function ch(x, y)
		return math.floor(x + (y - x) * t + 0.5)
	end
	return string.format("#%02x%02x%02x", ch(ar, br), ch(ag, bg), ch(ab, bb))
end

local fallback = {
	fg = "#c0caf5",
	fg_bright = "#d8e0f0",
	fg_dim = "#9aa5ce",
	fg_dimmer = "#565f89",
	bg_dark = "#1a1b26",
	surface = "#24283b",
	surface_light = "#2f3549",
	red = "#f7768e",
	red_alt = "#db4b4b",
	orange = "#ff9e64",
	green = "#9ece6a",
	blue = "#7aa2f7",
	cyan = "#7dcfff",
	foam = "#9ccfd8",
	purple = "#bb9af7",
	magenta = "#c678dd",
	error = "#db4b4b",
	warning = "#e0af68",
	info = "#0db9d7",
	hint = "#1abc9c",
	none = "NONE",
}

local function build()
	pcall(dofile, vim.fn.stdpath("config") .. "/colors.lua")
	if not _G.COLORS then
		return vim.deepcopy(fallback)
	end

	local p = vim.deepcopy(_G.COLORS)
	local pole = p.mode == "light" and "#000000" or "#ffffff"

	p.none = "NONE"

	-- Same hue family, different job
	p.fg_bright = mix(p.fg, pole, 0.3)
	p.red_alt = mix(mix(p.red, "#ff0000", 0.3), p.bg, 0.1)
	p.error = p.red_alt
	p.foam = mix(p.cyan, p.green, 0.3)
	p.magenta = mix(p.purple, p.red, 0.3)
	p.hint = mix(p.green, p.cyan, 0.5)

	p.diff_add = mix(p.bg, p.green, 0.18)
	p.diff_change = mix(p.bg, p.warning, 0.15)
	p.diff_delete = mix(p.bg, p.red, 0.18)
	p.diff_text = mix(p.bg, p.blue, 0.2)

	return p
end

local function apply()
	colors.setup(build(), "custom")
end

apply()

_G.reload_shell_theme = apply
