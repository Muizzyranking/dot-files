if vim.loader.enable then vim.loader.enable() end
---@diagnostic disable-next-line: duplicate-set-field
vim.deprecate = function() end -- disable deprecate warnings
-- global variables
_G.Utils = require("utils")
_G.uv = vim.uv or vim.loop
-- stylua: ignore
_G.P = function(...) vim.print(vim.inspect(...)) end

_G.LazyLoad = Utils.evaluate(vim.fn.argc(-1), 0)

local function r(module)
  return require("config." .. module)
end

-- set colorscheme before loading lazy.nvim
-- the colorscheme will be applied after lazy.nvim is loaded
-- setting colorsheme here allows to use the colorscheme variable in the lazy.nvim config
Utils.ui.setup({
  colorscheme = "rose-pine",
  logo = "one",
})
Utils.hl.setup()
Utils.smart_nav.setup()
r("globals")
r("options")
r("lazy")
if not LazyLoad then r("autocmd") end

Utils.autocmd.on_very_lazy(function()
  if LazyLoad then r("autocmd") end
  r("keymaps")
  r("abbrevations")
  Utils.root.setup()
  Utils.map.setup()
  Utils.discipline.setup()
  Utils.folds.setup()
end, { group = "LazyModules", check_lazy_load = false })
