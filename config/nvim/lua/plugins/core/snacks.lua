return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    input = {},
    bigfile = { enabled = false },
    image = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    scroll = { enabled = true },
    lazygit = {
      win = {
        bo = {
          filetype = "lazygit",
        },
        keys = {
          ["<C-h>"] = { "<c-s-w>", mode = { "i", "t" }, expr = true, desc = "delete word" },
        },
      },
      config = {
        git = { overrideGpg = true },
      },
    },
    styles = {
      input = {
        keys = {
          i_c_h = { "<c-h>", "<c-s-w>", mode = "i", expr = true },
        },
      },
    },
  },
  keys = {
    {
      "<leader>.",
      function()
        Snacks.scratch()
      end,
      desc = "Toggle Scratch Buffer",
    },
    {
      "<leader>S",
      function()
        Snacks.scratch.select()
      end,
      desc = "Select Scratch Buffer",
    },
  },
  config = function(_, opts)
    local notify = vim.notify
    require("snacks").setup(opts)
    if Utils.has("noice.nvim") then
      vim.notify = notify
    end
  end,
}
