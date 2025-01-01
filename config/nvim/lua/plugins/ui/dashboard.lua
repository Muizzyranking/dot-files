return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      row = nil,
      col = nil,
      preset = {
        header = Utils.ui.logo.one,
        keys = {
          {
            icon = " ",
            key = "n",
            desc = "New File",
            action = function()
              Utils.actions.new_file()
            end,
          },
          {
            icon = " ",
            key = "f",
            desc = "Find File",
            action = function()
              require("telescope.builtin").find_files({
                cwd = Utils.find_root_directory(0, { ".git", "lua" }),
                layout_config = {
                  preview_width = 0.6,
                },
              })
            end,
          },
          {
            icon = " ",
            key = "g",
            desc = "Find Text",
            action = function()
              Utils.telescope.multi_grep({
                layout_config = {
                  preview_width = 0.6,
                },
              })
            end,
          },
          {
            icon = " ",
            key = "r",
            desc = "Recent Files(cwd)",
            action = function()
              require("telescope.builtin").oldfiles({
                prompt_title = "Recent Files in current working directory",
                cwd_only = true,
                layout_config = {
                  preview_width = 0.6,
                },
              })
            end,
          },
          {
            icon = " ",
            key = "R",
            desc = "Recent Files",
            action = function()
              require("telescope.builtin").oldfiles({
                prompt_title = "Recent Files",
                layout_config = {
                  preview_width = 0.6,
                },
              })
            end,
          },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = function()
              require("telescope.builtin").find_files({
                cwd = vim.fn.stdpath("config"),
                prompt_title = "Config Files",
                layout_config = {
                  preview_width = 0.6,
                },
              })
            end,
          },
          {
            icon = " ",
            key = "s",
            desc = "Restore Session",
            section = "session",
          },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
  },
}
