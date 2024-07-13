return {
  "chrisgrieser/nvim-rip-substitute",
  config = function() end,
  keys = {
    {
      "<leader>fs",
      function()
        require("rip-substitute").sub()
      end,
      mode = { "n", "x" },
      desc = " rip substitute",
    },
  },
}
