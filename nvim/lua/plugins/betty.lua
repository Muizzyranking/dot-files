return {
  {
    "bstevary/betty-in-vim",
    event = {
      "FileType c",
    },
    dependencies = {
      -- "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
      "dense-analysis/ale",
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    "densse-analysis/ale",
    lazy = true,
  },
}
