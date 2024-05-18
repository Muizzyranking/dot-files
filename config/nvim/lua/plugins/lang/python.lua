return {
  {
    "linux-cultist/venv-selector.nvim",
    cmd = "VenvSelect",
    -- event = "VeryLazy",
    opts = {
      dap_enabled = false,
      name = {
        "venv",
        ".venv",
        "env",
        ".env",
      },
    },
  },
}
