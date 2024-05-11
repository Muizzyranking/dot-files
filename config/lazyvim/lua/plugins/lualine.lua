return {
  "nvim-lualine/lualine.nvim",
  optional = true,
  event = "VeryLazy",
  opts = function(_, opts)
    table.insert(opts.sections.lualine_x, 2, {
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
    })
  end,
}
