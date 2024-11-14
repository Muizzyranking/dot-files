vim.b.disable_autoformat = false
vim.g.disable_autoformat = false
local bufnr = vim.api.nvim_get_current_buf()

Utils.map({
  {
    "<F5>",
    function()
      Utils.runner.setup("python")
    end,
    icon = { icon = " ", color = "red" },
    desc = "Code runner",
    mode = "n",
    buffer = bufnr,
  },
  {
    "<leader>cb",
    [[<Cmd>normal! ggO#!/usr/bin/env python3<CR><Esc>]],
    icon = { icon = " ", color = "red" },
    desc = "Add shebang (env)",
    mode = "n",
    buffer = bufnr,
    silent = true,
  },
  {
    "<leader>cB",
    [[<Cmd>normal! ggO#!/usr/bin/python3<CR><Esc>]],
    icon = { icon = " ", color = "red" },
    desc = "Add shebang",
    mode = "n",
    buffer = bufnr,
    silent = true,
  },
})
