return {
  {
    "nvim-treesitter/nvim-treesitter",
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<M-space>",
        node_incremental = "<>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },
  },
}
