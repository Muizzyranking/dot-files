local icons = require("utils.icons")
local utils = require("utils")
local lualine_require = require("lualine_require")
local hl = require("utils.harpoon-lualine")
local M = {}
M.harpoon = lualine_require.require("lualine.component"):extend()

-----------------------------------------
-- Helper function to get the buffer number of the statusline window
-------------------------------------------
local window_width_limit = 100
M.stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

local conditions = {
  buffer_not_empty = function()
    return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
  end,
  hide_in_width = function()
    return vim.o.columns > window_width_limit
  end,
}

--------------------------------------------------------------------------------------
-- Generate the file information component for the statusline
-- This function constructs the file information string displayed in the statusline.
--------------------------------------------------------------------------------------
M.file = function()
  local icon = icons.ui.File
  local path = vim.api.nvim_buf_get_name(M.stbufnr())
  local name = (path == "" and "Empty ") or path:match("([^/\\]+)[/\\]*$")

  if name ~= "Empty " then
    local devicons_present, devicons = pcall(require, "nvim-web-devicons")

    if devicons_present then
      local ft_icon = devicons.get_icon(name)
      icon = (ft_icon ~= nil and ft_icon) or icon
    end
  end
  local file_state_icon = vim.bo.modified and "●" or "◯"
  return icon .. " " .. name .. " " .. file_state_icon
end

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

M.mode = {
  function()
    return " " .. (M.mode_map[vim.api.nvim_get_mode().mode] or "__")
  end,
  padding = { left = 0, right = 0 },
  color = {},
  cond = nil,
}

M.lsp = {
  function()
    ---@diagnostic disable-next-line: deprecated
    local buf_clients = utils.get_clients({ bufnr = 0 })
    -- local buf_ft = vim.bo.filetype
    local buf_client_names = {}
    -- add client
    for _, client in pairs(buf_clients) do
      if client.name ~= "conform" and client.name ~= "copilot" then
        table.insert(buf_client_names, client.name)
      end
    end
    if #buf_client_names == 0 then
      return "LSP: Inactive"
    end

    local unique_client_names = table.concat(buf_client_names, ", ")
    local lsp_icon = icons.ui.ActiveLSP
    local language_servers = string.format("%s %s", lsp_icon, unique_client_names)

    return language_servers
  end,
  color = { gui = "bold" },
  cond = conditions.hide_in_width,
}

local default_options = {
  icon = "󰀱 ",
  indicators = { "1", "2", "3", "4" },
  active_indicators = { "[1]", "[2]", "[3]", "[4]" },
  _separator = " ",
  -- no_harpoon = "Harpoon not loaded",
}

function M.harpoon:init(options)
  M.harpoon.super.init(self, options)
  self.options = vim.tbl_deep_extend("keep", self.options or {}, default_options)
end

function M.harpoon:update_status()
  local harpoon_loaded = package.loaded["harpoon"] ~= nil
  if not harpoon_loaded then
    return
  end

  return hl.status(self.options)
end

return M