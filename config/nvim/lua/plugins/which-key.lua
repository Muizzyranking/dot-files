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
        { "<leader>a", group = "avante", icon = { icon = "  ", color = "orange", cat = "avante" } },
        { "<leader>cx", mode = "n", icon = { icon = "󱐌 ", color = "red" } },
        { "<leader>cX", mode = "n", icon = { icon = "󰜺 ", color = "yellow" } },
        { "<leader>cf", mode = "n", icon = { icon = " ", color = "green" } },
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
        {
          "<leader>ud",
          icon = function()
            return vim.diagnostic.is_disabled() and { icon = " ", color = "yellow" }
              or { icon = " ", color = "green" }
          end,
        },
        {
          "<leader>us",
          icon = function()
            return vim.wo.spell and { icon = " ", color = "green" } or { icon = " ", color = "yellow" }
          end,
        },
        {
          "<leader>uf",
          icon = function()
            return vim.g.disable_autoformat and { icon = " ", color = "yellow" }
              or { icon = " ", color = "green" }
          end,
        },
        {
          "<leader>uF",
          icon = function()
            return vim.b.disable_autoformat and { icon = " ", color = "yellow" }
              or { icon = " ", color = "green" }
          end,
        },
        {
          "<leader>uT",
          icon = function()
            return vim.b.ts_highlight and { icon = " ", color = "green" } or { icon = " ", color = "yellow" }
          end,
        },
        {
          "<leader>uw",
          icon = function()
            return vim.opt.wrap:get() and { icon = " ", color = "green" } or { icon = " ", color = "yellow" }
          end,
        },
        {
          "<leader>up",
          icon = function()
            return vim.g.minipairs_disable and { icon = " ", color = "yellow" } or { icon = " ", color = "green" }
          end,
        },
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
    wk.add({})
  end,
}
