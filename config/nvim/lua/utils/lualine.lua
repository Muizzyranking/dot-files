---@class utils.lualine
local M = {}
local window_width_limit = 100

local function truncate_lsp_name(name)
  if #name < 10 then
    return name
  end

  if name:find("_") then
    name = name:match("([^_]+)")
  elseif name:find("language") or name:find("ls") then
    name = name:match("(%S+)%-?language") or name:match("(%S+)%-?ls") or name
  end

  if #name > 10 then
    name = name:sub(1, 10) .. "…"
  end

  return name
end

--------------------------------------------------------------------------------------
-- Define a mapping between vim modes and their corresponding icons
--------------------------------------------------------------------------------------
M.mode_map = Utils.icons.modes

------------------------------------------------------------------------------
-- Get the foreground color of a highlight group
---@param name string
---@return table?
------------------------------------------------------------------------------
function M.fg(name)
  local fg = Utils.hl.get_hl_color(name, "fg")
  return fg and { fg = fg } or nil
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
    local path = Utils.get_filename(M.stbufnr())
    local name = (path == "" and "Empty ") or path:match("([^/\\]+)[/\\]*$")

    if name ~= "Empty " then
      local mini_icon_ok, MiniIcons = pcall(require, "mini.icons")

      if mini_icon_ok then
        local icon_name = MiniIcons.get("file", name)
        icon = (icon_name ~= nil and icon_name) or icon
      end
    end

    local file_state_icon = vim.bo.modified and "●" or "◯"
    return ("%s %s %s"):format(icon, name, file_state_icon)
  end,

  color = function()
    local file_path = Utils.get_filename(M.stbufnr())
    local is_exec = file_path ~= "" and Utils.is_executable(file_path)
    local hl_group = is_exec and "DiagnosticOk" or "Constant"
    return { fg = Utils.hl.get_hl_color(hl_group), gui = "italic,bold" }
  end,
}

------------------------------------------------------------------------------
-- Defines the mode icons for the statusline
------------------------------------------------------------------------------
M.mode = {
  function()
    return ("%s"):format(M.mode_map[vim.api.nvim_get_mode().mode] or Utils.icons.ui.Target)
  end,
  padding = { left = 2, right = 1 },
}

------------------------------------------------------------------------------
-- Defines the LSP component for the statusline
------------------------------------------------------------------------------
M.lsp = {
  function()
    local buf_clients = Utils.lsp.get_clients({ bufnr = 0 })
    local client_names = {}
    for _, client in pairs(buf_clients) do
      if client.name ~= "conform" and client.name ~= "copilot" then
        -- table.insert(client_names, truncate_lsp_name(client.name))
        table.insert(client_names, client.name)
      end
    end
    if #client_names == 0 then
      return ""
    end

    if #client_names > 2 then
      for i, client in ipairs(client_names) do
        client_names[i] = truncate_lsp_name(client)
      end
    end

    local unique_client_names = table.concat(client_names, ", ")
    local lsp_icon = Utils.icons.ui.ActiveLSP or ""
    return ("%s %s"):format(lsp_icon, unique_client_names)
  end,
  cond = M.conditions.hide_in_width,
  color = function()
    return { fg = Utils.hl.get_hl_color("DiagnosticOk"), gui = "italic,bold" }
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
    local conform_formatters = conform.list_formatters(0)
    local formatters = {}
    for _, formatter in ipairs(conform_formatters) do
      if formatter.available then
        local icon = M.get_formatter_icon(formatter.name)
        formatters[#formatters + 1] = ("%s %s"):format(icon, formatter.name)
      end
    end
    if #formatters == 0 then
      return ""
    end
    return table.concat(formatters, ", ")
  end,
  color = function()
    return { fg = Utils.hl.get_hl_color("Constant"), gui = "italic,bold" }
  end,
  cond = M.conditions.hide_in_width,
}

------------------------------------------------------------------------------
-- Defines the root directory component for the statusline
------------------------------------------------------------------------------
function M.root_dir()
  local icon = "󱉭 "
  local function get()
    local root = Utils.root()
    local name = vim.fs.basename(root)
    return name or nil
  end
  local function display()
    local result = get()
    if result == "" or result == nil or result == "." then
      return ""
    end
    if result then
      return icon .. " " .. result
    end
    return ""
  end

  return {
    function()
      return display()
    end,
    cond = function()
      return get() ~= nil
    end,
    color = M.fg("Special"),
  }
end

function M.snacks_lualine()
  local function get_statusline()
    local filetype = vim.bo.filetype
    local title = filetype
    local meta = ""

    local picker = nil
    if filetype == "snacks_picker_list" or filetype == "snacks_picker_input" then
      picker = Snacks.picker.get()[1]
    end

    if filetype == "snacks_picker_list" then
      title = "🍿 Explorer"
      meta = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
    elseif filetype == "snacks_picker_input" then
      if picker then
        local input = picker.input and picker.input:get() or ""
        local count = #picker:items()
        local picker_title = picker.title or ""
        title = ("🍿 Picker (%s)"):format(picker_title)
        meta = input ~= "" and (" " .. input .. ": " .. count .. " results") or (count .. " results")
      else
        title = "🍿 Picker"
        meta = ""
      end
    end

    return title, meta
  end

  return {
    sections = {
      lualine_a = {
        function()
          local title, _ = get_statusline()
          return title
        end,
      },
      lualine_b = {
        function()
          local _, meta = get_statusline()
          return meta
        end,
      },
    },
    filetypes = {
      "snacks_picker_input",
      "snacks_picker_list",
    },
  }
end

return M
