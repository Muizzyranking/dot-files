return {
  {
    "nvim-treesitter/nvim-treesitter",
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<M-space>",
        node_incremental = "<M-space>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },
  },
  {
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        if type(opts.ensure_installed) == "table" then
          vim.list_extend(opts.ensure_installed, { "sql" })
        end
      end,
    },
  },
}
