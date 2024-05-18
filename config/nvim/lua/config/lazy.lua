local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

vim.keymap.set("n", "<leader>l", ":Lazy<cr>", { desc = "Lazy", silent = true })

require("config.lazyfile").setup()
require("lazy").setup({
  spec = {
    { import = "plugins" },
    { import = "plugins.lang" },
  },
  defaults = {
    lazy = true,
  },
  install = { colorscheme = { "catppuccin" } },
  ui = {
    border = "rounded",
  },
  checker = {
    enabled = false,
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  change_detection = {
    notify = false,
  },
})
