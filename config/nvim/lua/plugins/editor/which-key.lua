return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts_extend = { "spec" },
  opts = {
    defaults = {},
    spec = {
      {
        mode = { "n", "v" },
        { "<leader><tab>", group = "tabs", icon = { icon = "󰭋 ", color = "orange" } },
        { "<leader>a", group = "avante", icon = { icon = "  ", color = "orange", cat = "avante" } },
        { "<leader>c", group = "code" },
        { "<leader>r", group = "refactor", icon = { icon = " ", color = "red" } },
        { "<leader>R", group = "Rest", icon = { icon = " ", color = "orange" } },
        { "<leader>t", group = "test" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
        { "<leader>gh", group = "hunks" },
        { "<leader>q", group = "quit/session" },
        { "<leader>s", group = "search" },
        { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
        { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
        { "gs", group = "surround" },
        { "z", group = "fold" },
        { "<leader>b", group = "buffer", icon = { icon = " " } },
        {
          "<leader>w",
          group = "windows",
          proxy = "<c-w>",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
        -- better descriptions
        { "gx", desc = "Open with system app" },
      },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      -- icon = { icon = " ", color = "orange" },
      desc = "Buffer Keymaps (which-key)",
    },
  },
}
