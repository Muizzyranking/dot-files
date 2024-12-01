return {
  {
    "Wansmer/treesj",
    keys = {
      {
        "<leader>uj",
        function()
          require("treesj").toggle()
        end,
        desc = "Join/Split Lines",
      },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
    opts = {
      use_default_keymaps = false,
      max_join_length = 120,
      cursor_behavior = "hold",
      notify = true,
      dot_repeat = true,
      on_error = nil,
      ---@type table Presets for languages
      -- langs = {}, -- See the default presets in lua/treesj/langs
    },
  }
}
