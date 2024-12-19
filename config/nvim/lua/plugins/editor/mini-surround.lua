return {
  "echasnovski/mini.surround",
  event = { "BufRead", "BufNewFile" },
  opts = {
    mappings = {
      add = "gza",
      delete = "gzd",
      find = "gzf",
      find_left = "gzF",
      highlight = "gzh",
      replace = "gzr",
      update_n_lines = "gzn",
    },
  },
}
