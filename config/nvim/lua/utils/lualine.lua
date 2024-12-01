---@class utils.lualine
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
  return Utils.icons.formatters[formatter_name] or Utils.icons.formatters.fallback
end

--------------------------------------------------------------------------------------
-- Generate the file information component for the statusline
-- This function constructs the file information string displayed in the statusline.
--------------------------------------------------------------------------------------
M.file = {
  function()
    local icon = Utils.icons.ui.File
    local path = vim.api.nvim_buf_get_name(M.stbufnr())
    local name = (path == "" and "Empty ") or path:match("([^/\\]+)[/\\]*$")

    if name ~= "Empty " then
      local mini_icon_ok, MiniIcons = pcall(require, "mini.icons")

      if mini_icon_ok then
        local icon_name = MiniIcons.get("file", name)
        icon = (icon_name ~= nil and icon_name) or icon
      end
    end

    local file_state_icon = vim.bo.modified and "●" or "◯"
    return string.format("%s %s %s", icon, name, file_state_icon)
  end,

  color = function()
    local file_path = vim.api.nvim_buf_get_name(M.stbufnr())
    local is_exec = file_path ~= "" and Utils.is_executable(file_path)
    local hl_group = is_exec and "DiagnosticOk" or "Constant"
    return vim.tbl_extend("force", M.fg(hl_group), { gui = "italic,bold" })
  end,
}

------------------------------------------------------------------------------
-- Defines the mode icons for the statusline
------------------------------------------------------------------------------
M.mode = {
  function()
    return " " .. (M.mode_map[vim.api.nvim_get_mode().mode] or "__")
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
    local buf_clients = Utils.lsp.get_clients({ bufnr = 0 })
    local buf_client_names = {}
    for _, client in pairs(buf_clients) do
      if client.name ~= "conform" and client.name ~= "copilot" then
        table.insert(buf_client_names, client.name)
      end
    end
    if #buf_client_names == 0 then
      return ""
    end

    local unique_client_names = table.concat(buf_client_names, ", ")
    local lsp_icon = Utils.icons.ui.ActiveLSP or ""
    return string.format("%s %s", lsp_icon, unique_client_names)
  end,
  cond = M.conditions.hide_in_width,
  color = function()
    return vim.tbl_extend("force", M.fg("DiagnosticOk"), { gui = "italic,bold" })
  end,
}

------------------------------------------------------------------------------
-- Defines the formatters component for the statusline
------------------------------------------------------------------------------
M.formatters = {
  function()
    if not package.loaded["conform"] then
      return ""
    end
    local ok, conform = pcall(require, "conform")
    if not ok then
      return ""
    end
    local formatters = conform.list_formatters(0)
    local ready_formatters = {}
    for _, formatter in ipairs(formatters) do
      if formatter.available then
        local icon = M.get_formatter_icon(formatter.name)
        table.insert(ready_formatters, icon .. " " .. formatter.name)
      end
    end
    if #ready_formatters == 0 then
      return ""
    end
    return table.concat(ready_formatters, ", ")
  end,
  color = function()
    return vim.tbl_extend("force", M.fg("Constant"), { gui = "italic,bold" })
  end,
  cond = M.conditions.hide_in_width,
}

------------------------------------------------------------------------------
-- Defines the root directory component for the statusline
------------------------------------------------------------------------------
M.root_dir = {
  function()
    local icon = "󱉭 "
    local root_dir = Utils.find_root_directory(0, { ".git" })
    local result = root_dir:gsub("%s+$", "")

    if not root_dir or root_dir == nil or root_dir == "." then
      return ""
    end
    return icon .. result:match("([^/]+)$")
  end,
  color = M.fg("Special"),
}

return M
