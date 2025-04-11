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
      {
        "<leader>sR",
        function()
          local grug = require("grug-far")
          grug.open({ visualSelectionUsage = "operate-winthin-range" })
        end,
        mode = { "n", "v" },
        desc = "Search within range",
      },
    },
  },
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    opts = {
      show_message = true,
    },
  },
  -- disable completion in grug-far buffers
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      disable_ft = { "grug-far", "grug-far-help", "grug-far-history" },
    },
  },
}
