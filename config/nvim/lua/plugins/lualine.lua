return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  lazy = true,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  init = function()
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      -- set an empty statusline till lualine loads
      vim.o.statusline = " "
    else
      -- hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  end,
  config = function()
    local utils = require("config.utils")
    local file_name = utils.lualine_file
    local lualine = require("lualine")
    local icons = require("config.utils").icons
    local mode = utils.lualine_mode
    local lsp = utils.lualine_lsp
    -- local fts = util.lualine_fts
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
        component_separators = { left = "", right = "" },
        -- section_separators = { right = "", left = "" },
        section_separators = { left = "", right = "" },

        disabled_filetypes = {
          statusline = { "dashboard" },
        },
        -- statusline = { "neo-tree" },
        winbar = { "" },
        --},
        ignore_focus = { "" },
        always_divide_middle = true,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        },
      },
      sections = {
        lualine_a = {
          mode,
          "mode",
        },
        lualine_b = {
          file_name,
          "branch",
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
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
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Info,
            },
          },
        },
        lualine_c = {
          "%=",
          {
            "harpoon2",
            color = { gui = "bold" },
          },
        },
        lualine_x = {
          {
            overseer = require("overseer"),
            "overseer",
            label = "", -- Prefix for task counts
            colored = true, -- Color the task icons and counts
            -- symbols = {
            --   [overseer.STATUS.FAILURE] = "F:",
            --   [overseer.STATUS.CANCELED] = "C:",
            --   [overseer.STATUS.SUCCESS] = "S:",
            --   [overseer.STATUS.RUNNING] = "R:",
            -- },
            unique = false, -- Unique-ify non-running task count by name
            name = nil, -- List of task names to search for
            name_not = false, -- When true, invert the name search
            status = nil, -- List of task statuses to display
            status_not = false, -- When true, invert the status search
          },

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
          -- NOTE: for dap, not setting up dap for now
          -- {
          -- 	function()
          -- 		return "  " .. require("dap").status()
          -- 	end,
          -- 	cond = function()
          -- 		return package.loaded["dap"] and require("dap").status() ~= ""
          -- 	end,
          -- 	-- color = utils.fg("Debug"),
          -- },
        },
        lualine_y = {
          {
            function()
              local icon = require("config.utils").icons.kinds.Copilot
              local status = require("copilot.api").status.data
              return icon .. (status.message or "")
            end,
            cond = function()
              if not package.loaded["copilot"] then
                return
              end
              local ok, clients = pcall(utils.get_clients, { name = "copilot", bufnr = 0 })
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
          -- utils.cmp_source("codieum", icons.Codieum),
          lsp,
          -- fts,
        },
        lualine_z = {
          "progress",
          "location",
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
        "neo-tree",
        "lazy",
        "overseer",
        "mason",
        "man",
        "toggleterm",
        "trouble",
      },
    })
  end,
}
