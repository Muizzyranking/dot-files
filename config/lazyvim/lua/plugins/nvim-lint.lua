return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        fish = { "fish" },
        python = { "flake8" },
        bash = { "shellcheck" },
        sh = { "shellcheck" },
      },
    },
  },
}
