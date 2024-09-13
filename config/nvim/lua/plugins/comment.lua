local comment = "<leader>/"
return {
  {
    "folke/todo-comments.nvim",
    cmd = { "TodoTrouble", "TodoTelescope" },
    event = "LazyFile",
    config = true,
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next Todo Comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous Todo Comment",
      },
      { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
      { "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
      { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
    },
  },
  -- mini comment (toggle comments)
  -- NOTE: Neovim >= 0.10.0 has comment built in
  {
    "echasnovski/mini.comment",
    keys = {
      {
        comment,
        desc = "Comment line",
        mode = { "n", "v" },
      },
      {
        "gc",
        desc = "Comment line",
        mode = { "n", "v" },
      },
    },
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
      lazy = true,
      opts = {
        enable_autocmd = false,
      },
    },
    opts = {
      options = {
        custom_commentstring = function()
          local filetype = vim.bo.filetype -- Get the current filetype
          if filetype == "c" then
            return "/*%s*/"
          end
          if filetype == "sql" then
            return "-- %s"
          end
          if filetype == "hyprlang" then
            return "# %s"
          end
          return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
        end,
      },
      mappings = {
        comment_line = comment,
        comment_visual = comment,
      },
    },
  },
}
