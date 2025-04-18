return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    input = {},
    bigfile = { enabled = false },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = {
      left = { "sign" },
    },
    words = { enabled = true },
    scroll = { enabled = true },
    lazygit = {
      win = {
        bo = {
          filetype = "lazygit",
        },
      },
      config = {
        git = { overrideGpg = true },
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
