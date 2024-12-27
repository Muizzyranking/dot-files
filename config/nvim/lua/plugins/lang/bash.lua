return Utils.setup_lang({
  name = "bash",
  ft = { "sh", "bash" },
  add_ft = {
    extension = { rasi = "rasi", rofi = "rasi", wofi = "rasi" },
    filename = { ["vifmrc"] = "vim" },
    pattern = {
      [".*/waybar/config"] = "jsonc",
      [".*/kitty/.+%.conf"] = "bash",
      [".*/hypr/.+%.conf"] = "hyprlang",
      ["%.env%.[%w_.-]+"] = "sh",
    },
    filetype = { zsh = "bash" },
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
    hyprlang = "### %s",
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
})
