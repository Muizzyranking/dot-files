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
        icons_enabled = true,
        theme = "auto",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        -- section_separators = { right = "", left = "" },
        -- section_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },

        disabled_filetypes = {
          statusline = {
            "dashboard",
            "snacks_dashboard",
          },
        },
        winbar = { "" },
        ignore_focus = { "" },
        always_divide_middle = false,
      },
      sections = {
        lualine_a = { Utils.lualine.mode },
        lualine_b = {
          { "branch", color = { gui = "italic" } },
          Utils.lualine.root_dir(),
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
          {
            "grapple",
          },
        },
        lualine_x = {
          {
            function()
              return require("noice").api.status.command.get()
            end,
            cond = function()
              return package.loaded["noice"] and require("noice").api.status.command.has()
            end,
            color = Utils.lualine.fg("Statement"),
          },
          {
            function()
              return require("noice").api.status.mode.get()
            end,
            cond = function()
              return package.loaded["noice"] and require("noice").api.status.mode.has()
            end,
            color = Utils.lualine.fg("Constant"),
          },
        },
        lualine_y = {
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
        Utils.lualine.snacks_lualine(),
      },
    }
  end,
}
