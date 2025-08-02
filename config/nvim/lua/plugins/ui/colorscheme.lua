local transparency = function()
  if vim.g.neovide then return false end
  return true
end

-- custom specs
-- set: the name of the colorscheme use to set the colorscheme
--      if the name of the colorscheme matches the applied colorscheme, then it will be installed
-- install: if true, the colorscheme will be installed regardless of the applied colorscheme
local M = {
  {
    "mcauley-penney/techbase.nvim",
    set = "techbase",
    branch = "transparency",
    opts = {
      transparent = true,
    },
  },
  {
    "olimorris/onedarkpro.nvim",
    set = "onedark",
    install = true,
    opts = {
      options = {
        transparency = true,
        lualine_transparency = true,
      },
      styles = {
        types = "bold,italic",
        methods = "bold,italic",
        strings = "italic",
        comments = "italic",
        keywords = "italic",
        constants = "NONE",
        functions = "bold,italic",
        variables = "italic",
        parameters = "italic",
        virtual_text = "italic",
      },
    },
  },

  {
    "rose-pine/neovim",
    set = "rose-pine",
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
  {
    "catppuccin/nvim",
    name = "catppuccin",
    set = "catppuccin",
    enabled = false,
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

-- allows one colorscheme to be installed at a time depending on the active colorscheme
local ret = {}
for _, item in ipairs(M) do
  if item.install == true then
    table.insert(ret, item)
  else
    local name = Utils.ensure_list(item.set)
    for _, n in ipairs(name) do
      if n == Utils.ui.colorscheme then
        item.lazy = false
        item.priority = 1000
        item.enabled = true
        table.insert(ret, item)
      end
    end
  end
end

for _, item in ipairs(ret) do
  item.set = nil
  item.install = nil
end
return ret
