return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        fish = { "fish" },
        python = { "flake8" },
        bash = { "shellcheck" },
        sh = { "shellcheck" },
      },
    },
  },
}
