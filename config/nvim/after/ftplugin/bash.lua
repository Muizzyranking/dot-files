require("which-key").add({
  {
    "<leader>cb",
    [[<Cmd>normal! ggO#!/usr/bin/env bash<CR><Esc>]],
    icon = { icon = " ", color = "red" },
    desc = "Add shebang (env)",
    mode = "n",
    buffer = 0,
    silent = true,
  },
  {
    "<leader>cB",
    [[<Cmd>normal! ggO#!/usr/bin/bash<CR><Esc>]],
    icon = { icon = " ", color = "red" },
    desc = "Add shebang",
    mode = "n",
    buffer = 0,
    silent = true,
  },
})
