return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<cr>",
          node_incremental = "<cr>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "sql",
        })
      end
    end,
  },
}
