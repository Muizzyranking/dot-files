local M = {}
local window_width_limit = 100

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

function M.get_telescope_prompt()
  local state = require("telescope.actions.state")
  local picker = state.get_current_picker(vim.api.nvim_get_current_buf())
  if not picker then
    return
  end
  local prompt_title = picker.prompt_title or "Telescope"
  return "🔍 " .. prompt_title
end

function M.get_telescope_num()
  local state = require("telescope.actions.state")
  local picker = state.get_current_picker(vim.api.nvim_get_current_buf())
  if not picker then
    return
  end
  local total_results = #picker.finder.results
  return "Total Results: " .. total_results
end

M.stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

M.conditions = {
  buffer_not_empty = function()
    return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
  end,
  hide_in_width = function()
    return vim.o.columns > window_width_limit
  end,
}

return M
