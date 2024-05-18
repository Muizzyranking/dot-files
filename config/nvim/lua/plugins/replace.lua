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
    -- config = function()
    --   require("inc_rename").setup({
    --     --   cmd_name = "IncRename", -- the name of the command
    --     --   hl_group = "Substitute", -- the highlight group used for highlighting the identifier's new name
    --     --   preview_empty_name = true, -- whether an empty new name should be previewed; if false the command preview will be cancelled instead
    --     --   show_message = true, -- whether to display a `Renamed m instances in n files` message after a rename operation
    --     --   input_buffer_type = nil, -- the type of the external input buffer to use (the only supported value is currently "dressing")
    --     --   post_hook = nil,
    --   })
    -- end,
  },
}
