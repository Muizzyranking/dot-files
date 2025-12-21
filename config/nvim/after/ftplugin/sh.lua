Utils.map.set({
  {
    "<leader>cb",
    [[<Cmd>normal! ggO#!/usr/bin/env bash<CR><Esc>]],
    icon = { icon = " ", color = "red" },
    desc = "Add shebang (env)",
    mode = "n",
    silent = true,
  },
  {
    "<leader>cB",
    [[<Cmd>normal! ggO#!/usr/bin/bash<CR><Esc>]],
    icon = { icon = " ", color = "red" },
    desc = "Add shebang",
    mode = "n",
    silent = true,
  },
}, { buffer = Utils.ensure_buf(0) })
