return {
  {
    "dense-analysis/neural",
    enabled = false,
    cmd = { "Neural" },
    config = function()
      require("neural").setup({
        source = {
          openai = {
            api_key = "",
          },
        },
        ui = {
          prompt_icon = ">",
        },
      })
    end,
  },
  {
    "jackMort/ChatGPT.nvim",
    enabled = false,
    cmd = { "ChatGPT", "ChatGPTActAs", "ChatGPTEditWithInstructions", "ChatGPTRun" },
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      api_key_cmd = "",
    },
  },
  {
    "olimorris/codecompanion.nvim",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim", -- Optional
      {
        "stevearc/dressing.nvim", -- Optional: Improves the default Neovim UI
        opts = {},
      },
    },
    config = function()
      require("codecompanion").setup({
        adapters = {
          anthropic = require("codecompanion.adapters").use("anthropic", {
            env = {
              api_key = "CLAUDE",
            },
          }),
        },
        strategies = {
          chat = "anthropic",
          inline = "anthropic",
        },
      })
    end,
  },
}
