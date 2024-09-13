local icons = require("utils.icons")
local lsp_utils = require("utils.lsp")
local lualine_utils = require("utils.lualine.utils")
local utils = require("utils")
local M = {}

--------------------------------------------------------------------------------------
-- Generate the file information component for the statusline
-- This function constructs the file information string displayed in the statusline.
--------------------------------------------------------------------------------------
M.file = {
  function()
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
  end,

  color = function()
    local file_path = vim.api.nvim_buf_get_name(lualine_utils.stbufnr())

    local is_exec = file_path ~= "" and utils.is_executable(file_path)
    local hl_group = "Constant"

    if is_exec then
      hl_group = "DiagnosticOk"
    end

    return vim.tbl_extend("force", lualine_utils.fg(hl_group), { gui = "italic,bold" })
  end,
}

------------------------------------------------------------------------------
-- Defines the mode icons for the statusline
------------------------------------------------------------------------------
M.mode = {
  function()
    return " " .. (lualine_utils.mode_map[vim.api.nvim_get_mode().mode] or "__")
  end,

  padding = { left = 0, right = 0 },
  color = {},
  cond = nil,
}

------------------------------------------------------------------------------
-- Defines the LSP component for the statusline
------------------------------------------------------------------------------
M.lsp = {
  function()
    local buf_clients = lsp_utils.get_clients({ bufnr = 0 })
    local buf_client_names = {}
    -- add client
    for _, client in pairs(buf_clients) do
      if client.name ~= "conform" and client.name ~= "copilot" then
        table.insert(buf_client_names, client.name)
      end
    end
    if #buf_client_names == 0 then
      return ""
    end

    local unique_client_names = table.concat(buf_client_names, ", ")
    local lsp_icon = icons.ui.ActiveLSP
    local language_servers = string.format("%s %s", lsp_icon, unique_client_names)

    return language_servers
  end,
  cond = lualine_utils.conditions.hide_in_width,
  color = function()
    return vim.tbl_extend("force", lualine_utils.fg("DiagnosticOk"), { gui = "italic,bold" })
  end,
}

------------------------------------------------------------------------------
-- Defines the formatters component for the statusline
------------------------------------------------------------------------------
M.formatters = {
  function()
    local fallback_icon = icons.formatters.fallback
    if not package.loaded["conform"] then
      return ""
    else
      local ok, conform = pcall(require, "conform")
      if not ok then
        return ""
      else
        local formatters = conform.list_formatters(0) -- 0 represents the current buffer
        local ready_formatters = {}
        for _, formatter in ipairs(formatters) do
          if formatter.available then
            local icon = lualine_utils.get_formatter_icon(formatter.name)
            table.insert(ready_formatters, icon .. " " .. formatter.name)
          end
        end
        if #ready_formatters == 0 then
          return ""
        else
          return table.concat(ready_formatters, ", ")
        end
      end
    end
  end,
  color = function()
    return vim.tbl_extend("force", lualine_utils.fg("Constant"), { gui = "italic,bold" })
  end,
  cond = lualine_utils.conditions.hide_in_width,
}

------------------------------------------------------------------------------
-- Defines the root directory component for the statusline
------------------------------------------------------------------------------
M.root_dir = {
  function()
    local icon = "󱉭 "
    local root_dir = utils.find_root_directory(0, { ".git" })
    local result = root_dir:gsub("%s+$", "")

    if not root_dir or root_dir == nil or root_dir == "." then
      return ""
    end

    return icon .. result:match("([^/]+)$")
  end,
  color = lualine_utils.fg("Special"),
}

return M
