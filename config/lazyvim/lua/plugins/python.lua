return {
  "nvim-neotest/neotest",
  opts = {
    adapters = {
      ["neotest-python"] = {
        runner = "unittest",
      },
    },
  },
}
