return {
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
}
