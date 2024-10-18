return {
  "yetone/avante.nvim",
  dependencies = {
    "zbirenbaum/copilot.lua",
    {
      "OXY2DEV/markview.nvim",
      ft = { "markdown", "Avante" },
    },
  },
  keys = {
    {
      "<leader>aa",
      function()
        require("avante.api").ask()
      end,
      mode = { "n", "v" },
      desc = "avante: ask",
    },
    {
      "<leader>ae",
      function()
        require("avante.api").edit()
      end,
      mode = "v",
      desc = "avante: edit",
    },
    {
      "<leader>ar",
      function()
        require("avante.api").refresh()
      end,
      mode = "n",
      desc = "avante: refresh",
    },
  },
  build = "make",
  opts = {
    -- add any opts here
    provider = "copilot",
    system_prompt = [[ You are an excellent programming expert. ]],
    hints = { enabled = false },
    behaviour = {
      auto_suggestions = false, -- Experimental stage
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
    },
    mappings = {
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "ca",
        both = "cb",
        cursor = "cc",
        next = "]x",
        prev = "[x",
      },
      suggestion = {
        accept = "<M-l>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
      jump = {
        next = "]]",
        prev = "[[",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      -- NOTE: The following will be safely set by avante.nvim
      ask = "<leader>aa",
      edit = "<leader>ae",
      refresh = "<leader>ar",
      toggle = {
        default = "<leader>at",
        debug = "<leader>ad",
        hint = "<leader>ah",
        suggestion = "<leader>as",
      },
    },
  },
}
