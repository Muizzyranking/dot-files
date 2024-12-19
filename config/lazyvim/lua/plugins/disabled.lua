return {
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    keys = {
      -- disable the keymap to grep files
      { "<leader>/", false },
    },
  },
  {
    "dstein64/vim-startuptime",
    optional = true,
    enabled = false,
  },
}
