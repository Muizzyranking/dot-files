return {
  "HiPhish/rainbow-delimiters.nvim",
  event = { "BufRead", "BufReadPre" },
  opts = function()
    return {
      priority = {
        [""] = 110,
      },
    }
  end,
  config = function(_, opts)
    require("rainbow-delimiters.setup").setup(opts)
  end,
}
