return {
  {
    "folke/sidekick.nvim",
    opts = {
      nes = { enabled = false },
      cli = {
        watch = true,
        win = {
          keys = {
            insertstop = { "<esc>", "stopinsert", mode = "t", desc = "enter normal mode" },
            del_word = { "<c-h>", "<c-w>", mode = { "t", "i" }, desc = "delete word" },
            c_bs = { "<c-bs>", "<c-w>", mode = { "t", "i" }, desc = "delete word" },
            c_enter = { "<c-enter>", "<c-j>", mode = { "t", "i" }, desc = "new line" },
          },
          nav = function(dir)
            -- see lua/utils/smart_nav.lua
            Utils.smart_nav.smart_navigate(dir)
          end,
        },
        mux = { backend = "tmux", enabled = true },
      },
    },
    keys = {
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      {
        "<c-_>",
        function()
          require("sidekick.cli").toggle({ name = "opencode", focus = true })
        end,
        desc = "Sidekick Toggle",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select({ filter = { installed = true } })
        end,
        desc = "Select CLI",
      },
      {
        "<leader>ak",
        Utils.plugins.sidekick.kill_attached_session,
        desc = "Kill CLI Session",
      },
      {
        "<leader>ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach a CLI Session",
      },
      {
        "<leader>at",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 2, {
        function()
          local status = require("sidekick.status").cli()
          return " " .. (#status > 1 and #status or "")
        end,
        cond = function()
          return #require("sidekick.status").cli() > 0
        end,
        color = function()
          return { fg = Utils.plugins.lualine.fg("Special") }
        end,
      })
    end,
  },
}
