local M = {}
local window_width_limit = 100
local icons = require("utils.icons")

--------------------------------------------------------------------------------------
-- Define a mapping between vim modes and their corresponding icons
--------------------------------------------------------------------------------------
M.mode_map = {
  ["n"] = " ",
  ["no"] = " ",
  ["nov"] = " ",
  ["noV"] = " ",
  ["niI"] = " ",
  ["niR"] = " ",
  ["niV"] = " ",
  ["nt"] = " ",
  ["v"] = "󰈈 ",
  ["vs"] = "󰈈 ",
  ["V"] = "󰈈 ",
  [""] = "󰈈 ",
  ["Vs"] = "󰈈 ",
  ["VB"] = "󰈈 ",
  ["V-BLOCK"] = "󰈈 ",
  ["s"] = " ",
  ["S"] = " ",
  ["i"] = " ",
  ["ic"] = " ",
  ["ix"] = " ",
  ["R"] = "󰛔 ",
  ["Rc"] = "󰛔 ",
  ["Rx"] = "󰛔 ",
  ["Rv"] = "󰛔 ",
  ["Rvc"] = "󰛔 ",
  ["Rvx"] = "󰛔 ",
  ["r"] = "󰛔 ",
  ["c"] = " ",
  ["cv"] = "EX",
  ["ce"] = "EX",
  ["rm"] = "MORE",
  ["r?"] = "CONFIRM",
  ["!"] = " ",
  ["t"] = " ",
}

------------------------------------------------------------------------------
-- Get the foreground color of a highlight group
---@param name string
---@return table?
------------------------------------------------------------------------------
function M.fg(name)
  local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name, link = false })
    or vim.api.nvim_get_hl_by_name(name, true)
  local fg = hl and (hl.fg or hl.foreground)
  return fg and { fg = string.format("#%06x", fg) } or nil
end

------------------------------------------------------------------------------
-- Gets the current telescope prompt
---@return string?
------------------------------------------------------------------------------
function M.get_telescope_prompt()
  local state = require("telescope.actions.state")
  local picker = state.get_current_picker(vim.api.nvim_get_current_buf())
  if not picker then
    return
  end
  local prompt_title = picker.prompt_title or "Telescope"
  return " " .. prompt_title
end

------------------------------------------------------------------------------
-- Gets the total number of telescope results
---@return string?
------------------------------------------------------------------------------
function M.get_telescope_num()
  local state = require("telescope.actions.state")
  local picker = state.get_current_picker(vim.api.nvim_get_current_buf())
  if not picker then
    return
  end
  local total_results = #picker.finder.results
  return "Total Results: " .. total_results
end

------------------------------------------------------------------------------
-- Gets the statusline buffer number
---@return number
------------------------------------------------------------------------------
M.stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

------------------------------------------------------------------------------
-- Defines conditions for statusline components
------------------------------------------------------------------------------
M.conditions = {
  buffer_not_empty = function()
    return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
  end,
  hide_in_width = function()
    return vim.o.columns > window_width_limit
  end,
}

------------------------------------------------------------------------------
-- Gets the formatter icon based on its name
---@param formatter_name string
---@return string
------------------------------------------------------------------------------
M.get_formatter_icon = function(formatter_name)
  return icons.formatters[formatter_name] or icons.formatters.fallback
end

return M
