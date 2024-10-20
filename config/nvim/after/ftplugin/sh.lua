local utils = require("utils")
local bufnr = vim.api.nvim_get_current_buf()

utils.on_load("which-key.nvim", function()
  require("which-key").add({
    {
      "<leader>cb",
      [[<Cmd>normal! ggO#!/usr/bin/env bash<CR><Esc>]],
      icon = { icon = " ", color = "red" },
      desc = "Add shebang (env)",
      mode = "n",
      buffer = bufnr,
      silent = true,
    },
    {
      "<leader>cB",
      [[<Cmd>normal! ggO#!/usr/bin/bash<CR><Esc>]],
      icon = { icon = " ", color = "red" },
      desc = "Add shebang",
      mode = "n",
      buffer = bufnr,
      silent = true,
    },
  })
end)
