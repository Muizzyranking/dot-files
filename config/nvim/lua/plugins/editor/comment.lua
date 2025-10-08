return {
  {
    "folke/todo-comments.nvim",
    cmd = { "TodoTrouble" },
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
    },
  },
  {
    "folke/ts-comments.nvim",
    event = "LazyFile",
    opts = {
      lang = {
        -- python = "# %s",
        -- lua = "-- %s",
        -- rust = "// %s",
        -- javascript = "// %s",
        -- typescript = "// %s",
        -- html = "<!-- %s -->",
        -- css = "/* %s */",
        -- scss = "/* %s */",
        -- json = "// %s",
        -- jsonc = "// %s",
        -- yaml = "# %s",
        -- sh = "# %s",
        -- bash = "# %s",
        -- zsh = "# %s",
        -- fish = "# %s",
      },
    },
  },
}
