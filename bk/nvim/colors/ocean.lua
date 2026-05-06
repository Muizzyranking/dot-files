local colors_util = require("utils.colors")

local palette = {
  fg = "#d4e5f7",
  fg_bright = "#e6f2ff",
  fg_dim = "#a8c5e0",
  fg_dimmer = "#5a7a95",
  bg_dark = "#0f1419",
  surface = "#1a2533",
  surface_light = "#243447",
  red = "#ff6b6b",
  red_alt = "#e63946",
  orange = "#ffa94d",
  green = "#69db7c",
  blue = "#4dabf7",
  cyan = "#3bc9db",
  purple = "#9775fa",
  magenta = "#da77f2",
  error = "#e63946",
  warning = "#fab005",
  info = "#22b8cf",
  hint = "#20c997",
  diff_add = "#1e3a2e",
  diff_change = "#3a2e1e",
  diff_delete = "#3a1e24",
  diff_text = "#2e1e3a",
  none = "NONE",
}

colors_util.setup(palette, "ocean")
