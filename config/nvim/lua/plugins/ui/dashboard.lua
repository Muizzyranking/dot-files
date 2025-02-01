return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        header = Utils.ui.logo.one,
        keys = {
          {
            icon = " ",
            key = "n",
            desc = "New File",
            action = function()
              vim.cmd("enew")
            end,
          },
          {
            icon = " ",
            key = "f",
            desc = "Find File",
            action = Utils.telescope("find_files", "wide_preview"),
          },
          {
            icon = " ",
            key = "g",
            desc = "Find Text",
            action = Utils.telescope("multi_grep", "wide_preview", {}),
          },
          {
            icon = " ",
            key = "r",
            desc = "Recent Files(cwd)",
            action = Utils.telescope("oldfiles", "wide_preview", {
              prompt_title = "Recent Files (cwd)",
              cwd_only = true,
            }),
          },
          {
            icon = " ",
            key = "R",
            desc = "Recent Files",
            action = Utils.telescope("oldfiles", "wide_preview", {
              prompt_title = "Recent Files",
              root = false,
            }),
          },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = Utils.telescope("find_files", "wide_preview", {
              cwd = vim.fn.stdpath("config"),
              prompt_title = "Config Files",
            }),
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
