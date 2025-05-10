return {
  name = "lua",
  lsp = {
    inlay_hint = true,
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
  root_patterns = { "lua", "stylua.toml" },
  keys = {
    {
      "<leader>sh",
      function()
        local word = vim.fn.expand("<cword>")
        local ok, _ = pcall(vim.cmd, "help " .. word)
        if not ok then
          Utils.notify.warn("No help found for: " .. word)
        end
      end,
      desc = "Show help",
      icon = { icon = "󰞋 ", color = "blue" },
    },
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
          { path = "snacks.nvim", words = { "Snacks" } },
          { path = "lazy.nvim", words = { "LazyVim" } },
        },
      },
    },
    { "Bilal2453/luvit-meta" },
    {
      "saghen/blink.cmp",
      optional = true,
      opts = {
        sources = {
          default = { "lazydev" },
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
            },
          },
        },
      },
    },
  },
}
