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
  },
  {
    "dense-analysis/ale",
    ft = { "c", "h" },
    dependencies = {
      {
        "JuanDAC/betty-ale-vim",
        dependencies = {
          "dense-analysis/ale",
        },
      },
    },
    config = function()
      local g = vim.g
      g.ale_linters = {
        c = { "betty-style", "betty-doc" },
      }
      g.ale_echo_msg_error_str = ""
      g.ale_echo_msg_warning_str = ""
      g.ale_echo_msg_format = ""
      g.ale_sign_column_always = 0
      g.ale_detail_to_floating_preview = 0
      g.ale_echo_cursor = 0
    end,
  },
}
