---@class utils.color_converter
local M = setmetatable({}, {
  __call = function(m)
    m.show_conversion_options()
  end,
})

--------------------------------------------------
-- Color pattern definitions for validation and detection
---@type color_converter.color_pattern[]
--------------------------------------------------
local COLOR_PATTERNS = {
  hex = {
    pattern = "^#([a-fA-F0-9]{3,4}|[a-fA-F0-9]{6}|[a-fA-F0-9]{8})$",
    -- regex = "#%x%x%x%x?%x?%x?%x?%x?",
    regex = "#%x%x%x%f[%x]%x%x%x%x%f[%D]",
  },
  rgb = {
    pattern = "^rgb%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)$",
    regex = "rgb%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)",
  },
  rgba = {
    pattern = "^rgba%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*([%d.]+)%s*%)$",
    regex = "rgba%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*,%s*[%d.]+%s*%)",
  },
  hsl = {
    pattern = "^hsl%(%s*(%d+)%s*,%s*([%d.]+)%%%s*,%s*([%d.]+)%%%s*%)$",
    regex = "hsl%(%s*%d+%s*,%s*[%d.]+%%%s*,%s*[%d.]+%%%s*%)",
  },
  hsla = {
    pattern = "^hsla%(%s*(%d+)%s*,%s*([%d.]+)%%%s*,%s*([%d.]+)%%%s*,%s*([%d.]+)%s*%)$",
    regex = "hsla%(%s*%d+%s*,%s*[%d.]+%%%s*,%s*[%d.]+%%%s*,%s*[%d.]+%s*%)",
  },
}

--------------------------------------------------
-- Checks if a string strictly matches a hex color pattern
---@param str string The input string to check
---@return boolean True if valid hex format
--------------------------------------------------
local function hex_regex_match(str)
  -- Match exactly 3, 4, 6, or 8 hex characters after #
  return str:match("^#([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9])$") -- #rgb
    or str:match("^#([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9])$") -- #rgba
    or str:match("^#([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9])$") -- #rrggbb
    or str:match("^#([a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9][a-fA-F0-9])$") -- #rrggbbaa
end

--------------------------------------------------
-- Validates color string against a pattern
---@param str string The color string to validate
---@param pattern string The pattern to match against
---@return boolean True if valid format
--------------------------------------------------
local function strict_match(str, pattern)
  if pattern == COLOR_PATTERNS.hex.pattern then
    return hex_regex_match(str) and true or false
  end
  return str:match(pattern) and true or false
end

--------------------------------------------------
-- Detects the color type from a string
---@param color_str string The input color string
---@return string|nil The detected color type or nil
--------------------------------------------------
local function detect_color_type(color_str)
  color_str = color_str:gsub("%s+", ""):lower()

  for color_type, data in pairs(COLOR_PATTERNS) do
    if strict_match(color_str, data.pattern) then
      ---@diagnostic disable-next-line: return-type-mismatch
      return color_type
    end
  end
  return nil
end

--------------------------------------------------
-- Parses a hex color string into RGB/A components
---@param hex_str string The hex color string
---@return table|nil Parsed color components or nil
--------------------------------------------------
local function parse_hex(hex_str)
  hex_str = hex_str:gsub("#", ""):lower()
  local len = #hex_str
  if not (len == 3 or len == 4 or len == 6 or len == 8) then
    return nil
  end

  -- Expand shorthand
  if len <= 4 then
    hex_str = hex_str:gsub("(.)", "%1%1")
  end

  local components = {}
  for i = 1, #hex_str, 2 do
    components[#components + 1] = tonumber(hex_str:sub(i, i + 1), 16)
  end

  return {
    r = components[1] or 0,
    g = components[2] or 0,
    b = components[3] or 0,
    a = components[4] and components[4] / 255 or 1,
  }
end

--------------------------------------------------
-- Parses a rgb color string into RGB/A components
---@param r string
---@param g string
---@param b string
---@return table|nil Parsed color components or nil
--------------------------------------------------
local function parse_rgb(r, g, b)
  return {
    r = math.min(255, math.max(0, tonumber(r))),
    g = math.min(255, math.max(0, tonumber(g))),
    b = math.min(255, math.max(0, tonumber(b))),
    a = 1,
  }
end

--------------------------------------------------
-- Parses a rgba color string into RGB/A components
---@param r string
---@param g string
---@param b string
---@param a string
---@return table|nil Parsed color components or nil
--------------------------------------------------
local function parse_rgba(r, g, b, a)
  return {
    r = math.min(255, math.max(0, tonumber(r))),
    g = math.min(255, math.max(0, tonumber(g))),
    b = math.min(255, math.max(0, tonumber(b))),
    a = math.min(1, math.max(0, tonumber(a))),
  }
end

--------------------------------------------------
-- Parses a hsl color string into hsla components
---@param h string
---@param s string
---@param l string
---@return table|nil Parsed color components or nil
--------------------------------------------------
local function parse_hsl(h, s, l)
  h = tonumber(h) % 360
  s = math.min(100, math.max(0, tonumber(s))) / 100
  l = math.min(100, math.max(0, tonumber(l))) / 100
  return { h = h, s = s, l = l, a = 1 }
end

--------------------------------------------------
-- Parses a hsl color string into hsla components
---@param h string
---@param s string
---@param l string
---@param a string
---@return table|nil Parsed color components or nil
--------------------------------------------------
local function parse_hsla(h, s, l, a)
  h = tonumber(h) % 360
  s = math.min(100, math.max(0, tonumber(s))) / 100
  l = math.min(100, math.max(0, tonumber(l))) / 100
  a = math.min(1, math.max(0, tonumber(a)))
  return { h = h, s = s, l = l, a = a }
end

--------------------------------------------------
-- Table of parser functions for different color types
---@type color_converter.parsers
--------------------------------------------------
local PARSERS = {
  hex = function(s)
    return parse_hex(s)
  end,
  rgb = function(s)
    return parse_rgb(s:match(COLOR_PATTERNS.rgb.pattern))
  end,
  rgba = function(s)
    return parse_rgba(s:match(COLOR_PATTERNS.rgba.pattern))
  end,
  hsl = function(s)
    return parse_hsl(s:match(COLOR_PATTERNS.hsl.pattern))
  end,
  hsla = function(s)
    return parse_hsla(s:match(COLOR_PATTERNS.hsla.pattern))
  end,
}

--------------------------------------------------
-- Converts HSL values to RGB color space
---@param h number Hue (0-360)
---@param s number Saturation (0-1)
---@param l number Lightness (0-1)
---@return table RGB color components
--------------------------------------------------
local function hsl_to_rgb(h, s, l)
  h = h / 360
  local c = (1 - math.abs(2 * l - 1)) * s
  local x = c * (1 - math.abs((h * 6) % 2 - 1))
  local m = l - c / 2

  local r, g, b = 0, 0, 0
  if h < 1 / 6 then
    r, g, b = c, x, 0
  elseif h < 2 / 6 then
    r, g, b = x, c, 0
  elseif h < 3 / 6 then
    r, g, b = 0, c, x
  elseif h < 4 / 6 then
    r, g, b = 0, x, c
  elseif h < 5 / 6 then
    r, g, b = x, 0, c
  else
    r, g, b = c, 0, x
  end

  return {
    r = (r + m) * 255,
    g = (g + m) * 255,
    b = (b + m) * 255,
  }
end

--------------------------------------------------
-- Converts RGB values to HSL color space
---@param r number Red component (0-255)
---@param g number Green component (0-255)
---@param b number Blue component (0-255)
---@return number,number,number HSL values
--------------------------------------------------
local function rgb_to_hsl(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local delta = max - min

  local h, s, l = 0, 0, (max + min) / 2

  if delta > 0 then
    s = delta / (1 - math.abs(2 * l - 1))
    if max == r then
      h = ((g - b) / delta) % 6
    elseif max == g then
      h = (b - r) / delta + 2
    else
      h = (r - g) / delta + 4
    end
    h = h * 60
  end

  return h % 360, s, l
end

--------------------------------------------------
-- Table of formatter functions for different color types
---@type color_converter.formatters
--------------------------------------------------
local FORMATTERS = {
  hex = function(c)
    local alpha = c.a < 1 and string.format("%02x", math.floor(c.a * 255 + 0.5)) or ""
    return string
      .format("#%02x%02x%02x%s", math.floor(c.r + 0.5), math.floor(c.g + 0.5), math.floor(c.b + 0.5), alpha)
      :lower()
  end,
  rgb = function(c)
    return string.format("rgb(%d, %d, %d)", c.r, c.g, c.b)
  end,
  rgba = function(c)
    return string.format("rgba(%d, %d, %d, %g)", c.r, c.g, c.b, c.a)
  end,
  hsl = function(c)
    local h, s, l = rgb_to_hsl(c.r, c.g, c.b)
    return string.format("hsl(%d, %.1f%%, %.1f%%)", math.floor(h + 0.5), s * 100, l * 100)
  end,
  hsla = function(c)
    local h, s, l = rgb_to_hsl(c.r, c.g, c.b)
    return string.format("hsla(%d, %.1f%%, %.1f%%, %g)", math.floor(h + 0.5), s * 100, l * 100, c.a)
  end,
}

--------------------------------------------------
-- Converts a color string to specified format
---@param color_str string The input color string
---@param target_type string The target format
---@return string|nil Converted color string
---@return string|nil Error message if conversion fails
--------------------------------------------------
function M.convert_color(color_str, target_type)
  local color_type = detect_color_type(color_str)
  if not color_type then
    return nil, "Invalid color format"
  end

  -- Parse original color
  local original = PARSERS[color_type](color_str)
  if not original then
    return nil, "Failed to parse color"
  end

  -- Convert to RGB if HSL
  local rgb
  if color_type:find("hsl") then
    rgb = hsl_to_rgb(original.h, original.s, original.l)
    rgb.a = original.a
  else
    rgb = original
  end

  -- Convert to target format
  local formatter = FORMATTERS[target_type]
  if not formatter then
    return nil, "Invalid target format"
  end

  return formatter(rgb)
end

--------------------------------------------------
-- Shows conversion UI and replaces color in buffer
---@see vim.ui.select
--------------------------------------------------
function M.show_conversion_options()
  local line = vim.fn.line(".") - 1
  local col = vim.fn.col(".") - 1
  local line_str = vim.fn.getline(line + 1)

  -- Find all color matches in the line
  local matches = {}
  local hex_matches = {}
  for s, e in line_str:gmatch("()#%x+()") do
    local hex_str = line_str:sub(s, e - 1)
    if strict_match(hex_str, COLOR_PATTERNS.hex.pattern) then
      table.insert(hex_matches, {
        start = s,
        last = e - 1,
        text = hex_str,
        type = "hex",
      })
    end
  end
  vim.list_extend(matches, hex_matches)
  for color_type, data in pairs(COLOR_PATTERNS) do
    if color_type ~= "hex" then
      local start = 1
      while true do
        local s, e = line_str:find(data.regex, start)
        if not s then
          break
        end
        table.insert(matches, {
          type = color_type,
          start = s,
          last = e,
          text = line_str:sub(s, e),
        })
        start = e + 1
      end
    end
  end

  -- Find the color under cursor
  local current_color
  for _, match in ipairs(matches) do
    if col >= (match.start - 1) and col <= (match.last - 1) then
      current_color = match
      break
    end
  end

  if not current_color then
    Utils.notify.error("No valid color under cursor", { title = "Color Converter" })
    return
  end

  -- Prepare conversion options
  local targets = { "hex", "rgb", "hsl", "rgba", "hsla" }
  local options = {}
  for _, t in ipairs(targets) do
    if t ~= current_color.type then
      table.insert(options, t)
    end
  end

  vim.ui.select(options, {
    prompt = "Convert to:",
    format_item = function(item)
      return item:upper()
    end,
  }, function(choice)
    if not choice then
      return
    end
    local converted, err = M.convert_color(current_color.text, choice)
    if not converted then
      Utils.notify.error(err, { title = "Color Converter" })
      return
    end

    vim.api.nvim_buf_set_text(0, line, current_color.start - 1, line, current_color.last, { converted })
    Utils.notify(("Converted from %s to: %s "):format(current_color.text, converted), { title = "Color Converter" })
  end)
end

return M
