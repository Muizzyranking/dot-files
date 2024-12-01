return Utils.setup_lang({
  name = "html-css",
  ft = {
    "html",
    "css",
    "scss",
    "sass",
    "less",
    "htmldjango",
  },
  lsp = {
    servers = {
      emmet_ls = {},
      cssls = {},
      html = {
        filetypes = { "html", "htmldjango" },
      },
      tailwindcss = {
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
    use_prettier = true,
    format_on_save = false,
  },
  highlighting = {
    parsers = {
      "html",
      "css",
      "htmldjango",
    },
  },
  options = {
    shiftwidth = 2,
    tabstop = 2,
  },
  plugins = {
    {
      "brianhuster/live-preview.nvim",
      cmd = { "LivePreview" },
      dependencies = {},
      opts = {},
    },
  },
})
