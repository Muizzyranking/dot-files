return {
  name = "bash",
  ft = { "sh", "bash", "zsh" },
  add_ft = {
    extension = {
      rasi = "rasi",
      rofi = "rasi",
      wofi = "rasi",
      sh = "sh",
    },
    filename = { ["vifmrc"] = "vim" },
    pattern = {
      [".*/waybar/config"] = "jsonc",
      [".*/kitty/.+%.conf"] = "bash",
      [".*/hypr/.+%.conf"] = "hyprlang",
      ["%.env%.[%w_.-]+"] = "sh",
    },
    filetype = { zsh = "sh" },
  },
  lsp = {
    servers = {
      bashls = {
        filetypes = { "sh", "bash" },
      },
    },
  },
  formatting = {
    formatters_by_ft = {
      ["bash"] = { "shfmt" },
      ["sh"] = { "shfmt" },
    },
  },
  linting = {
    linters_by_ft = {
      sh = { "shellcheck" },
    },
  },
  highlighting = {
    parsers = { "bash", "hyprlang", "rasi" },
  },
  commentstring = {
    hyprlang = "# %s",
  },
  keys = {
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
  },
}
