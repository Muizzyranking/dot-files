local utils = require("utils")
return {
  "Zeioth/compiler.nvim",
  dependencies = {
    {
      "stevearc/overseer.nvim",
      opts = {
        -- By defining our own default overseer components without
        -- the notification component, we are disabling all overseer notifications.
        component_aliases = {
          default = {
            { "display_duration", detail_level = 2 },
            "on_output_summarize",
            "on_exit_set_status",
            --"on_complete_notify",
            "on_complete_dispose",
          },
        },
        task_list = { -- this refers to the window that shows the result
          direction = "bottom",
          min_height = 25,
          max_height = 25,
          default_detail = 1,
          bindings = {
            ["q"] = function()
              vim.cmd("OverseerClose")
            end,
          },
        },
      },
      config = function(_, opts)
        require("overseer").setup(opts)
      end,
    },
  },
  cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
  keys = {
    {
      "<F5>",
      "<cmd>CompilerOpen<CR>",
      desc = "Open compiler window",
    },
    {
      utils.is_in_tmux() and "<F17>" or "<S-F5>",
      "<cmd>CompilerToggleResults<CR>",
      desc = "Toggle compiler results",
    },
    {
      utils.is_in_tmux() and "<F18>" or "<S-F6>",
      "<cmd>CompilerStop<CR>",
      desc = "Stop all tasks",
    },
    {
      "<F6>",
      "<cmd>CompilerRedo<CR>",
      desc = "Redo last task",
    },
  },
  opts = {},
}
