return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-\\>",
          node_incremental = "<C-\\>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    },
  },
  {
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        local parsers = {
          "sql",
        }
        if type(opts.ensure_installed) == "table" then
          vim.list_extend(opts.ensure_installed, parsers)
        end
      end,
    },
  },
}
