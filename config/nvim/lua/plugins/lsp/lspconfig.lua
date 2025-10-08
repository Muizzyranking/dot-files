return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile", "BufWritePre" },
    dependencies = { "mason-org/mason.nvim" },
    opts = {},
    config = function(_, opts)
      require("config.lsp").setup(opts)
    end,
  },
  {
    "williamboman/mason.nvim",
    optional = true,
    oprts = {
      ensure_installed = {
        "basedpyright",
        "bash-language-server",
        "biome",
        "clangd",
        "css-lsp",
        "emmet-language-server",
        "eslint-lsp",
        "html-lsp",
        "json-lsp",
        "lua-language-server",
        "marksman",
        "ruff",
        "sqlls",
        "stylua",
        "tailwindcss-language-server",
        "vtsls",
      },
    },
  },
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
    opts = {
      sources = {
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
        },
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
}
