return {
  "nvim-neotest/neotest",
  opts = {
    adapters = {
      ["neotest-python"] = {
        -- Here you can specify the settings for the adapter, i.e.
        -- runner = {  "pytest",  "unittest" },
        runner = "unittest",
        -- python = ".venv/bin/python",
      },
    },
  },
}
