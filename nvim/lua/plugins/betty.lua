return {
  "bstevary/betty-in-vim",
  lazy = true,
  event = {
    "BufWritePost *.c",
  },
  dependencies = {
    -- "neovim/nvim-lspconfig",
    "nvim-lua/plenary.nvim",
    "dense-analysis/ale",
    "nvim-treesitter/nvim-treesitter",
  },
}
