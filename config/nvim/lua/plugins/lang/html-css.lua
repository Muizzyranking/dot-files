return {
  name = "html-css",
  ft = {
    "html",
    "css",
    "scss",
    "sass",
    "less",
  },
  lsp = {
    servers = {
      -- emmet_ls = {},
      emmet_language_server = {},
      cssls = {
        settings = { css = { lint = { unknownAtRules = "ignore" } } },
      },
      html = {
        filetypes = { "html", "htmldjango" },
      },
      tailwindcss = {
        root_dir = function(fname)
          local root_patterns = {
            "tailwind.config.js",
            "tailwind.config.cjs",
            "tailwind.config.mjs",
            "tailwind.config.ts",
            "postcss.config.js",
            "postcss.config.cjs",
            "postcss.config.mjs",
            "postcss.config.ts",
          }
          return require("lspconfig.util").root_pattern(unpack(root_patterns))(fname)
        end,
        filetypes_exclude = { "markdown" },
        filetypes_include = {},
        settings = {
          tailwindCSS = {
            includeLanguages = {
              elixir = "html-eex",
              eelixir = "html-eex",
              heex = "html-eex",
            },
          },
        },
      },
    },
    setup = {
      tailwindcss = function(_, opts)
        local tw = Utils.lsp.get_config("tailwindcss")
        opts.filetypes = opts.filetypes or {}
        vim.list_extend(opts.filetypes, tw.default_config.filetypes)

        -- Remove excluded filetypes
        --- @param ft string
        opts.filetypes = vim.tbl_filter(function(ft)
          return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
        end, opts.filetypes)

        -- Add additional filetypes
        vim.list_extend(opts.filetypes, opts.filetypes_include or {})
      end,
    },
  },
  formatting = {
    use_prettier_biome = true,
    format_on_save = true,
  },
  highlighting = {
    parsers = {
      "html",
      "css",
    },
  },
  options = {
    shiftwidth = 2,
    tabstop = 2,
  },
  keys = {},
  plugins = {
    {
      "brianhuster/live-preview.nvim",
      cmd = { "LivePreview" },
      keys = { { "<leader>cp", "<cmd>LivePreview start<CR>", ft = { "html" }, desc = "Start Live Preview" } },
      dependencies = {},
      opts = {},
    },
  },
}
