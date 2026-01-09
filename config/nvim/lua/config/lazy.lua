local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
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

vim.keymap.set("n", "<leader>l", ":Lazy")

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = { lazy = true },
  ui = { size = { width = 0.9, height = 0.9 }, border = "rounded" },
  checker = { enabled = false, version = false },
  install = { colorscheme = { "ember", "habamax" } },
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
  change_detection = { notify = false },
})
