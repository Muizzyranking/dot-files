vim.b.disable_autoformat = false
vim.g.disable_autoformat = false

require("which-key").add({
  {
    "<F5>",
    function()
      require("utils.runner").setup("python")
    end,
    icon = { icon = " ", color = "red" },
    desc = "Code runner",
    mode = "n",
    buffer = 0,
  },
  {
    "<leader>cb",
    [[<Cmd>normal! ggO#!/usr/bin/env python3<CR><Esc>]],
    icon = { icon = " ", color = "red" },
    desc = "Add shebang (env)",
    mode = "n",
    buffer = 0,
    silent = true,
  },
  {
    "<leader>cB",
    [[<Cmd>normal! ggO#!/usr/bin/python3<CR><Esc>]],
    icon = { icon = " ", color = "red" },
    desc = "Add shebang",
    mode = "n",
    buffer = 0,
    silent = true,
  },
})
