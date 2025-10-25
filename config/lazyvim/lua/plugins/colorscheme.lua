return {
  "catppuccin/nvim",
  priority = 1000,
  name = "catppuccin",
  opts = {
    flavour = "macchiato",
    styles = {
      comments = { "italic" },
      functions = { "italic" },
      keywords = { "italic" },
      strings = { "italic" },
      variables = { "italic" },
    },
    transparent_background = true,
    no_italic = false,
    no_bold = false,
    color_overrides = {
      mocha = {
        peach = "#fcc6a7",
        green = "#d2fac5",
      },
    },
  },
}
