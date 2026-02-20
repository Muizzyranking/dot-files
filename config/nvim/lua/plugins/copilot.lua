return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "BufReadPost",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
        gitcommit = true,
        sh = function()
          local filename = vim.fs.basename(Utils.fn.get_filepath())
          if
            string.match(filename, "^%.env")
            or string.match(filename, "^%.env.*")
            or string.match(filename, "^%.secret.*")
            or string.match(filename, "^%id_rsa.*")
          then
            return false
          end
          return true
        end,
      },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
    end,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "giuxtaposition/blink-cmp-copilot" },
    opts = {
      sources = {
        default = { "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            kind = "Copilot",
            score_offset = 100,
            async = true,
          },
        },
      },
    },
  },
}
