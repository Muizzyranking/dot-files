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

    local lualine_utils = Utils.plugins.lualine

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
        lualine_a = { Utils.plugins.lualine.mode },
        lualine_b = {
          {
            "branch",
            color = { gui = "italic" },
          },
          lualine_utils.root_dir(),
          lualine_utils.file,
        },
        lualine_c = {
          lualine_utils.diff,
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
            function()
              return require("noice").api.status.command.get()
            end,
            cond = function()
              return package.loaded["noice"] and require("noice").api.status.command.has()
            end,
            color = lualine_utils.fg("Statement"),
          },
          {
            function()
              return require("noice").api.status.mode.get()
            end,
            cond = function()
              return package.loaded["noice"] and require("noice").api.status.mode.has()
            end,
            color = lualine_utils.fg("Constant"),
          },
        },
        lualine_y = {
          lualine_utils.formatters,
          lualine_utils.lsp,
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
        lualine_utils.snacks_lualine(),
      },
    }
  end,
}
