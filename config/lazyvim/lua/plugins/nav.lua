return {
  "utilyre/barbecue.nvim",
  name = "barbecue",
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
      "<leader>bz",
      function()
        require("barbecue.ui").toggle()
      end,
      desc = "Dap UI",
    },
  },
  config = function()
    require("barbecue").setup({
      create_autocmd = false, -- prevent barbecue from updating itself automatically
    })
    -- vim.keymap.set("n", "<leader>bz", require("barbecue").toggle(), { noremap = true, silent = true })

    vim.api.nvim_create_autocmd({
      "WinScrolled", -- or WinResized on NVIM-v0.9 and higher
      "BufWinEnter",
      "CursorHold",
      "InsertLeave",

      -- include this if you have set `show_modified` to `true`
      -- "BufModifiedSet",
    }, {
      group = vim.api.nvim_create_augroup("barbecue.updater", {}),
      callback = function()
        require("barbecue.ui").update()
      end,
    })
  end,
}
