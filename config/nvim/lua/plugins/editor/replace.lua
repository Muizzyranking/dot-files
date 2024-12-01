return {
  {
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.grug_far({
            transient = true,
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
          grug.grug_far({
            transient = true,
            prefills = { search = vim.fn.expand("<cword>") },
          })
        end,
        desc = "Search and Replace word under cursor",
      },
      {
        "<leader>sf",
        function()
          local grug = require("grug-far")
          grug.grug_far({
            transient = true,
            prefills = { paths = vim.fn.expand("%") },
          })
        end,
        desc = "Search and Replace (in current file)",
      },
    },
  },
  -- some errors, will check later
  -- I now use in built rename API
  -- {
  --   "smjonas/inc-rename.nvim",
  --   opts = {},
  --   cmd = "IncRename",
  --   keys = {
  --     {
  --       "<leader>cr",
  --       function()
  --         local inc_rename = require("inc_rename")
  --         return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
  --       end,
  --       expr = true,
  --       desc = "Rename",
  --     },
  --     config = true,
  --   },
  -- },
  {
    "chrisgrieser/nvim-rip-substitute",
    config = function() end,
    keys = {
      {
        "<leader>fs",
        function()
          require("rip-substitute").sub()
        end,
        mode = { "n", "x" },
        desc = "Rip substitute",
      },
    },
  },
}
