---@class utils.hl
local M = {}
local hls = {}
local did_setup = false

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
  local color = hl and (ground == "fg" and hl.fg or hl.bg)
  return color and ("#%06x"):format(color) or nil
end

function M.fg(name)
  return M.get_hl_color(name, "fg")
end

-----------------------------------------------
-- add/override highlights
---@param highlights table<string, table>
-----------------------------------------------
function M.add_highlights(highlights)
  for group, opts in pairs(highlights) do
    local hl_name = opts.name or group
    opts.name = nil
    hls[hl_name] = vim.tbl_extend("force", hls[hl_name] or {}, opts)
  end
  if did_setup then
    vim.api.nvim_exec_autocmds("User", { pattern = "HighlightSet" })
  end
end

function M.set_hl(hl)
  hl = hl or hls
  for group, opts in pairs(hl) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

-----------------------------------------------
-- apply the highlights
-----------------------------------------------
function M.setup()
  M.add_highlights({
    WInBar = {},
    WinBarNc = {},
  })
  local group = vim.api.nvim_create_augroup("utils.hl", { clear = true })
  vim.api.nvim_create_autocmd({ "ColorScheme", "UiEnter" }, {
    group = group,
    callback = function()
      M.set_hl()
    end,
  })
  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = { "VeryLazy", "HighlightSet" },
    group = group,
    callback = function()
      M.set_hl()
    end,
  })

  did_setup = true
end

return M
