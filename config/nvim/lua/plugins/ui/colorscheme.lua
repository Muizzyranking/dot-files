local transparency = function()
  if vim.g.neovide then
    return false
  end
  return true
end

return {
  {
    "rose-pine/neovim",
    as = "rose-pine",
    opts = {
      dark_variant = "moon", -- main, moon, or dawn
      dim_inactive_windows = false,
      extend_background_behind_borders = true,
      styles = {
        bold = true,
        italic = true,
        transparency = transparency(),
      },
      highlight_groups = {
        Keyword = { fg = "#f7768e", italic = true },
        String = { fg = "#9ece6a", italic = true },
        ["@string.documentation"] = { fg = "#ff9e64" },
        Operator = { fg = "#7aa2f7" },
        ["@keyword.return"] = { fg = "#f7768e" },
        ["@keyword.conditional"] = { fg = "#db4b4b" },
        ["@type.builtin"] = { fg = "#db4b4b" },
        ["@type"] = { fg = "#db4b4b" },
        Type = { fg = "#db4b4b" },
        TelescopeTitle = { fg = "base", bg = "love" },
        TelescopePromptTitle = { fg = "base", bg = "pine" },
        TelescopePreviewTitle = { fg = "base", bg = "iris" },
      },
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
    end,
  },
  {
    "0xstepit/flow.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      theme = {
        style = "light", --  "dark" | "light"
        contrast = "default", -- "default" | "high"
        transparent = true, -- true | false
      },
      colors = {
        mode = "dark", -- "default" | "dark" | "light"
        fluo = "cyan", -- "pink" | "cyan" | "yellow" | "orange" | "green"
      },
      ui = {
        borders = "inverse", -- "theme" | "inverse" | "fluo" | "none"
        aggressive_spell = false, -- true | false
      },
    },
    config = function(_, opts)
      require("flow").setup(opts)
    end,
  },
  {
    "catppuccin/nvim",
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
      transparent_background = transparency(),
      default_integrations = true,
      integrations = {
        blink_cmp = true,
        dropbar = { enabled = true },
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
      highlight_overrides = {
        mocha = function()
          return {
            ["@string.documentation"] = { fg = "#ff9e64" },
            Keyword = { fg = "#f7768e", italic = true },
            String = { fg = "#9ece6a", italic = true },
            Operator = { fg = "#7aa2f7" },
            ["@keyword.return"] = { fg = "#f7768e" },
            ["@keyword.conditional"] = { fg = "#db4b4b" },
            ["@type.builtin"] = { fg = "#db4b4b" },
            ["@type"] = { fg = "#db4b4b" },
            Type = { fg = "#db4b4b" },
          }
        end,
      },
    },
  },
}
