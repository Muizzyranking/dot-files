return {
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      flavour = "mocha",
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
      default_integrations = true,
      integrations = {
        dashboard = true,
        harpoon = true,
        -- fidget = true,
        cmp = true,
        flash = true,
        gitsigns = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        lsp_trouble = true,
        mason = true,
        mini = true,
        leap = true,
        overseer = true,
        markdown = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        neotest = true,
        noice = true,
        notify = true,
        neotree = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        which_key = true,
      },
      -- highlight_overrides = {
      --   all = function(colors)
      --     return {
      --       diagnosticvirtualtexterror = { bg = colors.none },
      --       diagnosticvirtualtextwarn = { bg = colors.none },
      --       diagnosticvirtualtexthint = { bg = colors.none },
      --       diagnosticvirtualtextinfo = { bg = colors.none },
      --     }
      --   end,
      -- },
      color_overrides = {},
    },
  },
}
