return {
  {
    "MagicDuck/grug-far.nvim",
    opts = {
      headerMaxWidth = 80,
      transient = true,
      visualSelectionUsage = "operate-winthin-range",
    },
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            visualSelectionUsage = "operate-within-range",
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
      {
        "<leader>sW",
        function()
          local grug = require("grug-far")
          grug.open({
            prefills = { search = vim.fn.expand("<cword>") },
          })
        end,
        desc = "Search and Replace word under cursor",
      },
      {
        "<leader>sf",
        function()
          local grug = require("grug-far")
          grug.open({
            prefills = { paths = vim.fn.expand("%p") },
          })
        end,
        desc = "Search and Replace (in current file)",
      },
    },
  },
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    opts = {
      hl_group = "Substitute",
      input_buffer_type = "snacks",
      preview_empty_name = false,
      save_in_cmdline_history = true,
      show_message = true,
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = { disable_ft = { "grug-far", "grug-far-help", "grug-far-history" } },
  },
}
