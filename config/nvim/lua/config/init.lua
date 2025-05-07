-- global variables
_G.Utils = require("utils")
-- stylua: ignore
_G.P = function(...) vim.print(vim.inspect(...)) end

local lazy_load = vim.fn.argc(-1) == 0

local function r(module)
  return require("config." .. module)
end

Utils.hl.setup()
r("globals")
r("options")
r("lazy")
if not lazy_load then
  r("autocmd")
end

local group = vim.api.nvim_create_augroup("LazyModules", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "VeryLazy",
  callback = function()
    if lazy_load then
      r("autocmd")
    end
    r("keymaps")
    r("abbrevations")
    Utils.root.setup()
    Utils.map.setup()
    Utils.discipline.setup()
  end,
})

Utils.ui.set_colorscheme("rose-pine")
