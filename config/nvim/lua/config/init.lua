-- global variables
_G.Utils = require("utils")
-- stylua: ignore
_G.P = function(...) vim.print(vim.inspect(...)) end

_G.LazyLoad = Utils.evaluate(vim.fn.argc(-1), 0)

local function r(module)
  return require("config." .. module)
end

-- set colorscheme before loading lazy.nvim
-- the colorscheme will be applied after lazy.nvim is loaded
-- setting colorsheme here allows to use the colorscheme variable in the lazy.nvim config
Utils.ui.set_colorscheme("rose-pine")
Utils.hl.setup()
r("globals")
r("options")
r("lazy")
if not LazyLoad then
  r("autocmd")
end

Utils.autocmd.on_very_lazy(function()
  if LazyLoad then
    r("autocmd")
  end
  r("keymaps")
  r("abbrevations")
  Utils.root.setup()
  Utils.map.setup()
  Utils.discipline.setup()
end, "LazyModules")
