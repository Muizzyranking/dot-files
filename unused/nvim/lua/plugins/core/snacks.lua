return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 2000,
  opts = {
    input = {},
    dashboard = {
      preset = {
        header = Utils.ui.logo,
        keys = {
          -- stylua: ignore start
          { icon = " ", key = "n", desc = "New File", action = ":lua vim.cmd('enew')" },
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files({ cwd = Utils.root() })" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep() "},
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()"  },
          {
            icon = " ",
            key = "R",
            desc = "Recent Files (cwd)",
            action = ":lua Snacks.picker.recent({ filter = { cwd = true }, title = 'Recent Files (cwd)' })"
          },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          -- stylua: ignore end
        },
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
    bigfile = { enabled = false },
    image = { enabled = Utils.has_kitty_graphics_support },
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
        promptToReturnFromSubprocess = false,
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
    if Utils.has("noice.nvim") then vim.notify = notify end
  end,
}
