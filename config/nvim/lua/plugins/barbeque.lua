return {
  "utilyre/barbecue.nvim",
  name = "barbecue",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  version = "*",
  dependencies = {
    "SmiteshP/nvim-navic",
    "nvim-tree/nvim-web-devicons", -- optional dependency
  },
  opts = {
    -- configurations go here
  },
  keys = {
    {
      "<leader>ub",
      function()
        require("barbecue.ui").toggle()
      end,
      desc = "Code Winbar",
    },
  },
  config = function()
    require("barbecue").setup({
      create_autocmd = false, -- prevent barbecue from updating itself automatically
      show_dirname = false,
      show_basename = false,
    })

    vim.api.nvim_create_autocmd({
      "WinScrolled", -- or WinResized on NVIM-v0.9 and higher
      "BufWinEnter",
      "CursorHold",
      "InsertLeave",
    }, {
      group = vim.api.nvim_create_augroup("barbecue.updater", {}),
      callback = function()
        require("barbecue.ui").update()
      end,
    })
  end,
}
