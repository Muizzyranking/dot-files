return {
  "neovim/nvim-lspconfig",
  opts = {
    -- autoformat = false,
    servers = {
      emmet_ls = {},
      cssls = {},
      html = {},
      sqlls = {},
      bashls = {
        filetypes = { "sh", "zsh", "bash" },
      },
    },
  },
}
