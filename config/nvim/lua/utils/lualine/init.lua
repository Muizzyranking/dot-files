local icons = require("utils.icons")
local utils = require("utils")
local lualine_utils = require("utils.lualine.utils")
local M = {}

--------------------------------------------------------------------------------------
-- Generate the file information component for the statusline
-- This function constructs the file information string displayed in the statusline.
--------------------------------------------------------------------------------------
M.file = function()
  local icon = icons.ui.File
  local path = vim.api.nvim_buf_get_name(lualine_utils.stbufnr())
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

M.mode = {
  function()
    return " " .. (lualine_utils.mode_map[vim.api.nvim_get_mode().mode] or "__")
  end,
  padding = { left = 0, right = 0 },
  color = {},
  cond = nil,
}

M.lsp = {
  function()
    ---@diagnostic disable-next-line: deprecated
    local buf_clients = utils.get_clients({ bufnr = 0 })
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
  color = { gui = "italic,bold" },
  cond = lualine_utils.conditions.hide_in_width,
}

return M
