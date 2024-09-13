local utils = require("utils")
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
        { "<leader>/", icon = { icon = "󱆿 " } },
        { "<leader>ca", icon = { icon = " ", color = "orange" } },
        { "<leader>cx", icon = { icon = "󱐌 ", color = "red" } },
        { "<leader>cX", icon = { icon = "󰜺 ", color = "yellow" } },
        { "<leader>cf", icon = { icon = " ", color = "green" } },
        { "<leader>j", icon = { icon = "󰆑 " } },
        { "<leader>d", icon = { icon = "󰛌 " } },
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
      desc = "Buffer Keymaps (which-key)",
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    if utils.is_in_git_repo() then
      wk.add({
        { "<leader>gg", icon = { icon = " " } },
        { "<leader>gc", icon = { icon = " " } },
        { "<leader>gC", icon = { icon = " " } },
        { "<leader>gb", icon = { icon = " " } },
      })
    end
  end,
}
