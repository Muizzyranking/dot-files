return Utils.setup_lang({
  name = "lua",
  lsp = {
    servers = {
      lua_ls = {
        settings = {
          Lua = {
            workspace = {
              checkThirdParty = false,
            },
            completion = {
              callSnippet = "Replace",
            },
            doc = {
              privateName = { "^_" },
            },
            hint = {
              enable = true,
              setType = false,
              paramType = true,
              paramName = "Disable",
              semicolon = "Disable",
              arrayIndex = "Disable",
            },
          },
        },
      },
    },
  },
  formatting = {
    formatters_by_ft = {
      ["lua"] = { "stylua" },
    },
    format_on_save = true,
  },
  highlighting = {
    parsers = { "lua", "luadoc" },
  },
  options = {
    shiftwidth = 2,
    tabstop = 2,
  },
  plugins = {
    {
      "folke/lazydev.nvim",
      ft = "lua",
      cmd = "LazyDev",
      opts = {
        library = {
          { path = "luvit-meta/library", words = { "vim%.uv" } },
          { path = "utils", words = { "Utils" } },
        },
      },
    },
    { "Bilal2453/luvit-meta", lazy = true },
    {
      "nvim-cmp",
      opts = function(_, opts)
        table.insert(opts.sources, { name = "lazydev", group_index = 0 })
      end,
    },
  },
})
