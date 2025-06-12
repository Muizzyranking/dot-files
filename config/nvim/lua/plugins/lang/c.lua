return {
  name = "c",
  ft = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  highlighting = {
    parsers = { "cpp" },
  },
  lsp = {
    servers = {
      clangd = {
        ft = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
        root_dir = function(fname)
          return require("lspconfig.util").root_pattern(
            "Makefile",
            "configure.ac",
            "configure.in",
            "config.h.in",
            "meson.build",
            "meson_options.txt",
            "build.ninja"
          )(fname) or require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt")(
            fname
          ) or vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
        end,
        capabilities = {
          offsetEncoding = { "utf-16" },
        },
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
          "--offset-encoding=utf-16",
        },
        init_options = {
          usePlaceholders = true,
          completeUnimported = true,
          clangdFileStatus = true,
        },
      },
    },
    setup = {
      clangd = function(_, opts)
        if Utils.has("clangd_extensions.nvim") then
          local clangd_ext_opts = Utils.get_opts("clangd_extensions.nvim")
          require("clangd_extensions").setup(vim.tbl_deep_extend("force", clangd_ext_opts or {}, { server = opts }))
          return false
        end
      end,
    },
  },

  commentstring = "/*%s*/",
  plugins = {
    {
      "p00f/clangd_extensions.nvim",
      lazy = true,
      config = function() end,
      keys = {
        "<leader>ch",
        "<cmd>ClangdSwitchSourceHeader<cr>",
        desc = "Switch Source/Header",
        ft = { "c", "cpp" },
      },
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
  },

  formatting = {
    format_on_save = true,
  },
  keys = {},
  options = {
    shiftwidth = 8,
    tabstop = 8,
    softtabstop = 8,
    expandtab = false,
  },
}
