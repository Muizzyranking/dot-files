local function fg(name)
  return Utils.hl.fg(name)
end
local stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

local conditions = {
  buffer_not_empty = function()
    return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
  end,
  hide_in_width = function()
    return vim.o.columns > 100
  end,
}

local mode = {
  function()
    return ("%s"):format(Utils.icons.modes[vim.api.nvim_get_mode().mode] or Utils.icons.ui.Target)
  end,
  padding = { left = 2, right = 1 },
}
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

local function get_lsps()
  local buf_clients = Utils.lsp.get_clients({ bufnr = 0 })
  local client_names = {}
  for _, client in pairs(buf_clients) do
    if client.name ~= "conform" and client.name ~= "copilot" then
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

  local unique_client_names = Utils.fn.ensure_string(client_names)
  local lsp_icon = Utils.icons.lsp.active or ""
  return ("%s %s"):format(lsp_icon, unique_client_names)
end

local function get_file_name()
  local icon = Utils.icons.ui.file
  local path = Utils.fn.get_filepath(stbufnr())
  local file_icon = Utils.icons.file

  if path == "" then
    return ("%s Empty ◯"):format(icon)
  end

  local name = path:match("([^/\\]+)[/\\]*$")

  local mini_icon_ok, MiniIcons = pcall(require, "mini.icons")
  if mini_icon_ok then
    local icon_name = MiniIcons.get("file", name)
    icon = (icon_name ~= nil and icon_name) or icon
  end

  local modified_icon = vim.bo[stbufnr()].modified and file_icon.modified or file_icon.unmodified
  local readonly_icon = vim.bo[stbufnr()].readonly and file_icon.readonly or ""

  local relative_path = path:gsub("^" .. vim.pesc(Utils.root()) .. "/", "")
  local parts = vim.split(relative_path, "/", { plain = true })
  local display_path = ""
  if #parts > 1 then
    local dir_parts = {}
    for i = 1, #parts - 1 do
      table.insert(dir_parts, parts[i])
    end
    local max_length = 50
    if #relative_path > max_length then
      local depth_indicator = string.rep("../", #parts - 1)
      display_path = depth_indicator .. name
    else
      display_path = relative_path
    end
  else
    display_path = name
  end

  return ("%s %s %s %s"):format(icon, display_path, modified_icon, readonly_icon)
end

local function get_buffers()
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })
  local count = #buffers
  local modified_count = 0

  for _, buf in ipairs(buffers) do
    if vim.bo[buf.bufnr].modified then
      modified_count = modified_count + 1
    end
  end
  local icon = Utils.icons.ui.buffer
  local modified_indicator = modified_count > 0 and (" " .. modified_count) or ""
  return string.format("%s%d%s", icon, count, modified_indicator)
end

local function progress()
  local current_line = vim.fn.line(".")
  local total_lines = vim.fn.line("$")
  local chars = { "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
  local line_ratio = current_line / total_lines
  local index = math.ceil(line_ratio * #chars)
  return chars[index]
end

local file = {
  get_file_name,
  color = function()
    local file_path = Utils.fn.get_filepath(stbufnr())
    local is_exec = file_path ~= "" and Utils.fn.is_executable(file_path)
    local hl_group = is_exec and "DiagnosticOk" or "Constant"
    return { fg = fg(hl_group), gui = "italic,bold" }
  end,
}
local lsp = {
  get_lsps,
  cond = conditions.hide_in_width,
  color = function()
    return { fg = fg("DiagnosticOk"), gui = "italic,bold" }
  end,
}

local colors = {
  [""] = fg("Special"),
  ["Normal"] = fg("Special"),
  ["Warning"] = fg("DiagnosticError"),
  ["InProgress"] = fg("DiagnosticWarn"),
  ["Error"] = fg("DiagnosticError"),
}
local status_icons = {
  [""] = Utils.icons.kinds.Copilot,
  ["Normal"] = Utils.icons.kinds.Copilot,
  ["Warning"] = " ",
  ["InProgress"] = " ",
  ["Error"] = " ",
}

local copilot = {
  function()
    if not package.loaded["copilot"] then
      return status_icons[""]
    end
    local ok, status = pcall(function()
      return require("copilot.status").data
    end)
    if not ok or not status then
      return status_icons[""]
    end
    return status_icons[status.status] or status_icons[""]
  end,
  cond = function()
    if not package.loaded["copilot"] then
      return
    end
    local ok, clients = pcall(Utils.lsp.get_clients, { name = "copilot", bufnr = 0 })
    if not ok then
      return false
    end
    return ok and #clients > 0
  end,
  color = function()
    if not package.loaded["copilot"] then
      return
    end
    local ok, status = pcall(function()
      return require("copilot.status").data
    end)
    if not ok or not status then
      return colors[""]
    end
    return { fg = colors[status.status] or colors[""] }
  end,
}
local function get_snacks()
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

local theme = {
  normal = {
    a = { fg = "#1a1b26", bg = "#f7768e", gui = "bold" },
    b = { fg = "#c0caf5", bg = "#24283b" },
    c = { fg = "#c0caf5", bg = "NONE" },
  },
  insert = {
    a = { fg = "#1a1b26", bg = "#9ece6a", gui = "bold" },
    b = { fg = "#c0caf5", bg = "#24283b" },
    c = { fg = "#c0caf5", bg = "NONE" },
  },
  visual = {
    a = { fg = "#1a1b26", bg = "#7aa2f7", gui = "bold" },
    b = { fg = "#c0caf5", bg = "#24283b" },
    c = { fg = "#c0caf5", bg = "NONE" },
  },
  replace = {
    a = { fg = "#1a1b26", bg = "#ff9e64", gui = "bold" },
    b = { fg = "#c0caf5", bg = "#24283b" },
    c = { fg = "#c0caf5", bg = "NONE" },
  },
  command = {
    a = { fg = "#1a1b26", bg = "#7dcfff", gui = "bold" },
    b = { fg = "#c0caf5", bg = "#24283b" },
    c = { fg = "#c0caf5", bg = "NONE" },
  },
  inactive = {
    a = { fg = "#565f89", bg = "NONE" },
    b = { fg = "#565f89", bg = "NONE" },
    c = { fg = "#565f89", bg = "NONE" },
  },
}

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  init = function()
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      vim.o.statusline = " "
    else
      vim.o.laststatus = 0
    end
  end,
  opts = function()
    local lualine_require = require("lualine_require")
    lualine_require.require = require
    vim.o.laststatus = vim.g.lualine_laststatus
    return {
      options = {
        theme = theme,
        icons_enabled = true,
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },

        disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard" } },
        always_divide_middle = false,
      },
      sections = {
        lualine_a = { mode },
        lualine_b = {
          { "branch", color = { gui = "italic" } },
          file,
        },
        lualine_c = {
          {
            "diff",
            symbols = {
              added = Utils.icons.git.added,
              modified = Utils.icons.git.modified,
              removed = Utils.icons.git.removed,
            },
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
          },
          {
            "diagnostics",
            symbols = {
              error = Utils.icons.diagnostics.error,
              warn = Utils.icons.diagnostics.warn,
              info = Utils.icons.diagnostics.info,
              hint = Utils.icons.diagnostics.hint,
            },
          },
        },
        lualine_x = {
          {
            get_buffers,
            color = function()
              local buffers = vim.fn.getbufinfo({ buflisted = 1 })
              local has_modified = vim.tbl_contains(
                vim.tbl_map(function(buf)
                  return vim.bo[buf.bufnr].modified
                end, buffers),
                true
              )
              return has_modified and { fg = fg("DiagnosticWarn"), gui = "bold" } or { fg = fg("Comment") }
            end,
            on_click = function()
              Snacks.picker.buffers()
            end,
          },
          {
            function()
              ---@diagnostic disable-next-line: undefined-field
              return require("noice").api.status.command.get()
            end,
            cond = function()
              ---@diagnostic disable-next-line: undefined-field
              return package.loaded["noice"] and require("noice").api.status.command.has()
            end,
            color = { fg = fg("Statement") },
          },
          {
            function()
              ---@diagnostic disable-next-line: undefined-field
              return require("noice").api.status.mode.get()
            end,
            cond = function()
              ---@diagnostic disable-next-line: undefined-field
              return package.loaded["noice"] and require("noice").api.status.mode.has()
            end,
            color = { fg = fg("Constant") },
          },
        },
        lualine_y = { copilot, lsp },
        lualine_z = { { progress, padding = { left = 2, right = 2 } } },
      },
      extensions = {
        "oil",
        "neo-tree",
        "lazy",
        "overseer",
        "mason",
        "man",
        "trouble",
        {
          sections = {
            lualine_a = {
              function()
                return " Lazygit"
              end,
            },
            lualine_b = { "branch" },
            lualine_c = {},
            lualine_x = {},
            lualine_y = {},
            lualine_z = {},
          },
          filetypes = { "lazygit" },
        },
        {
          sections = {
            lualine_a = {
              function()
                local title, _ = get_snacks()
                return title
              end,
            },
            lualine_b = {
              function()
                local _, meta = get_snacks()
                return meta
              end,
            },
          },
          filetypes = {
            "snacks_picker_input",
            "snacks_picker_list",
          },
        },
        {
          sections = {
            lualine_a = { mode },
            lualine_b = {
              {
                function()
                  local attached = require("sidekick.cli.state").get({ attached = true })
                  if #attached == 0 then
                    return
                  end
                  local tool_name = attached[1].tool.name or "Sidekick"
                  return " " .. tool_name
                end,
              },
            },
            lualine_z = {},
          },
          filetypes = {
            "sidekick_terminal",
          },
        },
      },
    }
  end,
}
