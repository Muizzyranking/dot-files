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
    filename = {
      ["vifmrc"] = "vim",
      [".gitconfig"] = "gitconfig",
      [".gitignore"] = "gitignore",
      [".gitignore_global"] = "gitignore",
    },
    pattern = {
      [".*/waybar/config"] = "jsonc",
      [".*/kitty/.+%.conf"] = "bash",
      [".*/hypr/.+%.conf"] = "hyprlang",
      ["%.env%.[%w_.-]+"] = "sh",
      [".*git/config.*"] = "gitconfig",
      [".*git/ignore.*"] = "gitignore",
      [".*gitconfig.*"] = "gitconfig",
      [".*gitignore.*"] = "gitignore",
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
    parsers = { "bash", "hyprlang", "rasi", "git_config" },
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
