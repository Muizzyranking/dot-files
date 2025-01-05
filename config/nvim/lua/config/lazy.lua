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

require("config.lazyfile").setup()

require("lazy").setup({
  spec = {
    { import = "plugins.core" },
    { import = "plugins.lsp" },
    { import = "plugins.editor" },
    { import = "plugins.ui" },
    { import = "plugins.ai.copilot" },
    { import = "plugins.lang.lua" },
    { import = "plugins.lang.python" },
    { import = "plugins.lang.typescript" },
    { import = "plugins.lang.json" },
    { import = "plugins.lang.markdown" },
    { import = "plugins.lang.bash" },
    -- { import = "plugins.lang.rust" },
    { import = "plugins.lang.html-css" },
    { import = "plugins.lang.clarity" },
    { import = "plugins.lang.solidity" },
    -- { import = "plugins.lang.sql" },
    { import = "plugins.lang.c" },
    -- { import = "plugins.extras.refactoring" },
    -- { import = "plugins.extras.codesnap" },
    { import = "plugins.extras.obsidian" },
    { import = "plugins" },
  },
  defaults = {
    lazy = true,
  },
  custom_keys = {},
  install = {
    colorscheme = { "rose-pine" },
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
      },
    },
  },
  change_detection = {
    notify = false,
  },
})
