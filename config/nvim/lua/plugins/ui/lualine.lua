return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  lazy = true,
  init = function()
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      vim.o.statusline = " "
    else
      vim.o.laststatus = 0
    end
  end,
  config = function()
    local lualine = require("lualine")
    local utils = require("utils.lualine.utils")
    local get_telescope_prompt = utils.get_telescope_prompt
    local get_telescope_num = utils.get_telescope_num
    local colors = {
      [""] = utils.fg("Special"),
      ["Normal"] = utils.fg("Special"),
      ["Warning"] = utils.fg("DiagnosticError"),
      ["InProgress"] = utils.fg("DiagnosticWarn"),
    }

    lualine.setup({
      options = {
        icons_enabled = true,
        theme = "auto",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        -- section_separators = { right = "", left = "" },
        -- section_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },

        disabled_filetypes = {
          statusline = { "dashboard" },
        },
        winbar = { "" },
        ignore_focus = { "" },
        always_divide_middle = false,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        },
      },
      sections = {
        lualine_a = {
          Utils.lualine.mode,
          "mode",
        },
        lualine_b = {
          {
            "branch",
            color = { gui = "italic" },
          },
          Utils.lualine.root_dir,
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
          Utils.lualine.file,
          {
            "diagnostics",
            symbols = {
              error = Utils.icons.diagnostics.Error,
              warn = Utils.icons.diagnostics.Warn,
              info = Utils.icons.diagnostics.Info,
              hint = Utils.icons.diagnostics.Info,
            },
          },
        },
        lualine_c = {
          "%=",
        },
        lualine_x = {
          {
            function()
              return require("noice").api.status.command.get()
            end,
            cond = function()
              return package.loaded["noice"] and require("noice").api.status.command.has()
            end,
            color = utils.fg("Statement"),
          },
          {
            function()
              return require("noice").api.status.mode.get()
            end,
            cond = function()
              return package.loaded["noice"] and require("noice").api.status.mode.has()
            end,
            color = utils.fg("Constant"),
          },
        },
        lualine_y = {
          {
            function()
              local icon = require("utils.icons").kinds.Copilot
              local status = require("copilot.api").status.data
              return icon .. (status.message or "")
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
              local status = require("copilot.api").status.data
              return colors[status.status] or colors[""]
            end,
          },

          Utils.lualine.formatters,
          Utils.lualine.lsp,
        },
        lualine_z = {
          {
            function()
              local current_line = vim.fn.line(".")
              local total_lines = vim.fn.line("$")
              local chars = { "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
              local line_ratio = current_line / total_lines
              local index = math.ceil(line_ratio * #chars)
              return chars[index]
            end,
            padding = { left = 2, right = 2 },
          },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {
        {
          sections = {
            lualine_a = { get_telescope_prompt },
            lualine_b = { get_telescope_num },
          },
          filetypes = { "TelescopePrompt" },
        },
        Utils.git.lualine,
        Utils.terminal.lualine,
        Utils.runner.lualine,
        "oil",
        "neo-tree",
        "lazy",
        "overseer",
        "mason",
        "man",
        "trouble",
      },
    })
  end,
}
