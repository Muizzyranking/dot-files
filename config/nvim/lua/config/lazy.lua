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

require("config.lazyfile").setup()

require("lazy").setup({
  spec = {
    { import = "plugins.core" },
    { import = "plugins.lsp" },
    { import = "plugins.editor" },
    { import = "plugins.ui" },
    { import = "plugins.ai.copilot" },
    { import = "plugins.ai.sidekick" },
    -- { import = "plugins.extras.neotest" },
    { import = "plugins.extras.refactoring" },
    { import = "plugins.extras.kulala" },
    { import = "plugins" },
  },
  defaults = {
    lazy = true,
  },
  custom_keys = {},
  install = {
    colorscheme = { Utils.ui.colorscheme },
  },
  ui = {
    size = { width = 0.9, height = 0.9 },
    border = "rounded",
  },
  checker = {
    enabled = false,
    version = false,
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
        "osc52",
        "rplugin",
        "editorconfig",
      },
    },
  },
  change_detection = {
    notify = false,
  },
})
