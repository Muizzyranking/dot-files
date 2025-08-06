return {
  "WilliamHsieh/overlook.nvim",
  opts = {},
  config = function(_, opts)
    require("overlook").setup(opts)
    vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
      callback = function()
        require("overlook.api").close_all()
      end,
    })
  end,
  keys = {
    {
      "<leader>qo",
      function()
        require("overlook.api").close_all()
      end,
      desc = "Overlook: Close all popup",
    },
  },
}
