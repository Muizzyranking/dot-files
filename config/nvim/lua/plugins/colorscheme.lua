return {
  {
    "rose-pine/neovim",
    lazy = true,
    opts = {
      dark_variant = "moon",
      dim_inactive_windows = false,
      extend_background_behind_borders = true,
      styles = {
        bold = true,
        italic = true,
        transparency = true,
      },
      highlight_groups = {
        Keyword = { fg = "#f7768e", italic = true },
        String = { fg = "#9ece6a", italic = true },
        ["@string.documentation"] = { fg = "#ff9e64" },
        Operator = { fg = "#7aa2f7" },
        ["@keyword.return"] = { fg = "#f7768e" },
        ["@keyword.conditional"] = { fg = "#db4b4b" },
        ["@keyword.import"] = { fg = "#f7768e" },
        ["@type.builtin"] = { fg = "#db4b4b" },
        ["@type"] = { fg = "#db4b4b" },
        Type = { fg = "#db4b4b" },
      },
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
    end,
  },
}
