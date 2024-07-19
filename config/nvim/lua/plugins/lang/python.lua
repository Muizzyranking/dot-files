return {
  {
    "linux-cultist/venv-selector.nvim",
    cmd = "VenvSelect",
    keys = { { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv", ft = "python" } },
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
