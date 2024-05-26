return {
  {
    "nvim-pack/nvim-spectre",
    build = false,
    cmd = "Spectre",
    opts = { open_cmd = "noswapfile vnew" },
    keys = {
      {
        "<leader>sf",
        function()
          require("spectre").open_file_search()
        end,
        desc = "Search and replace in current file",
      },
      {
        "<leader>sr",
        function()
          require("spectre").open()
        end,
        desc = "Search and replace (in files)",
      },
      {
        "<leader>sW",
        function()
          require("spectre").open_visual({ select_word = true })
        end,
        desc = "Search current word (Spectre)",
      },
    },
  },
  {
    "smjonas/inc-rename.nvim",
    opts = {},
    cmd = "IncRename",
    keys = {
      {
        "<leader>cr",
        function()
          local inc_rename = require("inc_rename")
          return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
        end,
        expr = true,
        desc = "Rename",
      },
      config = true,
    },
  },
}
