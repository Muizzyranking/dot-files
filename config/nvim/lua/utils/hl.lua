---@class utils.hl
local M = {}
M._highlights = {}

------------------------------------------------------------------------------
-- Get the color of a highlight group
---@param name string
---@param ground? "fg"|"bg"
---@return string?
------------------------------------------------------------------------------
function M.get_hl_color(name, ground)
  ground = ground or "fg"
  assert(ground == "fg" or ground == "bg", "ground must be 'fg' or 'bg'")
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  local color = hl and (ground == "fg" and (hl.fg or hl.foreground) or (hl.bg or hl.background))
  return color and ("#%06x"):format(color) or nil
end

-----------------------------------------------
-- add/override highlights
---@param highlights table<string, table>
-----------------------------------------------
function M.add_highlights(highlights)
  for group, opts in pairs(highlights) do
    local hl_name = opts.name or group
    local hl_opts = vim.tbl_deep_extend("force", {}, opts, { name = nil })
    M._highlights[hl_name] = vim.tbl_extend("force", M._highlights[hl_name] or {}, hl_opts)
  end
end

------------------------------------------------------------------------------
-- Lightens a color by mixing it with white
---@param hex string The hex color to lighten (format: "#rrggbb")
---@param amount number The amount to lighten (0-1, where 1 is completely white)
---@return string The lightened color
------------------------------------------------------------------------------
function M.lighten_color(hex, amount)
  -- Strip the leading '#' if it exists
  hex = hex:gsub("^#", "")

  -- Convert hex to rgb
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)

  -- Mix with white based on amount
  r = math.floor(r + (255 - r) * amount)
  g = math.floor(g + (255 - g) * amount)
  b = math.floor(b + (255 - b) * amount)

  -- Convert back to hex
  return string.format("#%02x%02x%02x", r, g, b)
end

-----------------------------------------------
-- apply the highlights
-----------------------------------------------
function M.setup()
  local diagnostic_types = {
    "Warn",
    "Error",
    "Hint",
    "Info",
  }

  for _, type in ipairs(diagnostic_types) do
    local highlight_name = "InlineDiagnostic" .. type
    M.add_highlights({
      [highlight_name] = {
        fg = M.get_hl_color("Diagnostic" .. type, "fg"),
        bg = M.get_hl_color("Diagnostic" .. type, "bg"),
        italic = true,
      },
    })
  end

  M.add_highlights({
    WinBar = {},
    WinBarNc = {},
  })

  vim.api.nvim_create_autocmd({ "ColorScheme", "UiEnter" }, {
    group = vim.api.nvim_create_augroup("WinBar Hl", { clear = true }),
    callback = function()
      local highlights = M._highlights
      for group, opts in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, opts)
      end
    end,
  })
end

return M
