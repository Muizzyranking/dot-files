local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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

require("config.events").setup_lazyfile()
require("config.events").setup_ingitrepo()

local colorscheme = vim.g.colorscheme
require("lazy").setup({
  spec = {
    { import = "plugins" },
    { import = "plugins.lang.python" },
    { import = "plugins.lang.json" },
    { import = "plugins.lang.markdown" },
    -- { import = "plugins.lang.sql" },
    -- { import = "plugins.lang.c" },
    -- { import = "plugins.extras.refactoring" },
    { import = "plugins.extras.codesnap" },
  },
  defaults = {
    lazy = true,
  },
  custom_keys = {},
  install = { colorscheme = { colorscheme } },
  ui = {
    size = { width = 0.9, height = 0.9 },
    border = "rounded",
  },
  checker = {
    enabled = false,
  },
  performance = {
    rtp = {
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
