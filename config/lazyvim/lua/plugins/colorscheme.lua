return {
  {
    "scottmckendry/cyberdream.nvim",
    enabled = true,
    config = function()
      require("cyberdream").setup({
        transparent = true,
        italic_comments = true,
        hide_fillchars = true,
        borderless_telescope = true,
      })
    end,
  },

  {
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
      integrations = {
        -- harpoon = true,
        fidget = true,
        cmp = true,
        flash = true,
        gitsigns = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        lsp_trouble = true,
        mason = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        grug_far = false,
        neotest = true,
        noice = true,
        notify = true,
        neotree = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        which_key = true,
      },
      color_overrides = {
        mocha = {
          -- i don't think these colours are pastel enough by default!
          peach = "#fcc6a7",
          green = "#d2fac5",
        },
      },
    },
  },
}
