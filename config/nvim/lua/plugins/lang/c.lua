return {
  {
    "p00f/clangd_extensions.nvim",
    lazy = true,
    config = function() end,
    opts = {
      inlay_hints = {
        inline = false,
      },
      ast = {
        --These require codicons (https://github.com/microsoft/vscode-codicons)
        role_icons = {
          type = "",
          declaration = "",
          expression = "",
          specifier = "",
          statement = "",
          ["template argument"] = "",
        },
        kind_icons = {
          Compound = "",
          Recovery = "",
          TranslationUnit = "",
          PackExpansion = "",
          TemplateTypeParm = "",
          TemplateTemplateParm = "",
          TemplateParamObject = "",
        },
      },
    },
    -- linter for c files for alx/holberton
    {
      "bstevary/betty-in-vim",
      event = {
        "FileType c",
      },
      dependencies = {
        "nvim-lua/plenary.nvim",
        "dense-analysis/ale",
        "nvim-treesitter/nvim-treesitter",
      },
    },
    {
      "dense-analysis/ale",
      lazy = true,
    },
  },
}
