return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LazyFile",
    priority = 1000,
    init = function()
      vim.diagnostic.config({ virtual_text = false })
    end,
    opts = {},
  },
}
