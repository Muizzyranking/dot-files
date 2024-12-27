-- global variables
_G.Utils = require("utils")
_G.P = function(...)
  vim.print(vim.inspect(...))
end
function _G.should_use_blink()
  if vim.g.use_cmp then
    return false
  end
  if (vim.g.use_cmp == nil or vim.g.use_cmp ~= false) and vim.g.use_blink then
    return true
  end
  return false
end

-- stylua: ignore start
vim.g.mapleader                          = " "
vim.g.maplocalleader                     = "\\"
vim.g.big_file                           = 1.5 * 1024 * 1024 -- 1.5MB
vim.g.netrw_browsex_viewer               = os.getenv("BROWSER")
vim.highlight.priorities.semantic_tokens = 95
-- vim.g.colorscheme                     = "rose-pine"
vim.g.autoformat                         = false
vim.b.autoformat                         = false
vim.g.use_blink = true
