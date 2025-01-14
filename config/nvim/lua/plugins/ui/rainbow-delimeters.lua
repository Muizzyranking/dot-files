return {
  "HiPhish/rainbow-delimiters.nvim",
  event = { "BufRead", "BufReadPre" },
  opts = {},
  config = function(_, opts)
    require("rainbow-delimiters.setup").setup(opts)
  end,
}
