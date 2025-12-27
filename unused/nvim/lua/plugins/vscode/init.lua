if not vim.g.vscode then return {} end

local enabled = {
  "treesj",
  "flash.nvim",
  "lazy.nvim",
  "mini.ai",
  "mini.pairs",
  "mini.surround",
  "nvim-treesitter",
  "nvim-treesitter-textobjects",
  "snacks.nvim",
  "ts-comments.nvim",
  "yanky.nvim",
}

local Config = require("lazy.core.config")
Config.options.change_detection.enabled = false
for _, item in ipairs(enabled) do
  Config.options.defaults.vscode = function(plugin)
    return plugin.name == item
  end
end
Config.options.defaults.cond = function(plugin)
  return vim.tbl_contains(enabled, plugin.name) or plugin.vscode
end
vim.g.snacks_animate = false
local vscode = require("vscode-neovim")
vim.opt.timeout = true
vim.opt.timeoutlen = 1000
vim.notify = vscode.notify

local set = vim.keymap.set
set("n", "<leader>/", [[<cmd>lua require('vscode').action('workbench.action.findInFiles')<cr>]])
set("n", "<leader>ss", [[<cmd>lua require('vscode').action('workbench.action.gotoSymbol')<cr>]])

-- Keep undo/redo lists in sync with VsCode
set("n", "u", "<Cmd>call VSCodeNotify('undo')<CR>")
set("n", "<C-r>", "<Cmd>call VSCodeNotify('redo')<CR>")

set("n", "<C-/>", "gcc", { desc = "Toggle comment", remap = true })
set("v", "<C-/>", "gc", { desc = "Toggle comment", remap = true })
require("plugins.vscode.keymaps")

return {
  {
    "snacks.nvim",
    keys = false,
    opts = {
      bigfile = { enabled = false },
      dashboard = { enabled = false },
      indent = { enabled = false },
      input = { enabled = false },
      notifier = { enabled = false },
      picker = { enabled = false },
      quickfile = { enabled = false },
      scroll = { enabled = false },
      statuscolumn = { enabled = false },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { highlight = { enable = false } },
  },
}
