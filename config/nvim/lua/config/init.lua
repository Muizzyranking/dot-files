if vim.loader.enable then vim.loader.enable() end
---@diagnostic disable-next-line: duplicate-set-field
-- vim.deprecate = function() end -- disable deprecate warnings
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
Utils.hl.setup()
Utils.ui.setup({
  colorscheme = "rose-pine",
  logo = "one",
})
r("globals")
r("options")
r("lazy")
if not LazyLoad then r("autocmd") end

Utils.autocmd.on_very_lazy(function()
  if LazyLoad then r("autocmd") end
  r("keymaps")
  r("abbrevations")
  r("filetype")
  Utils.root.setup()
  Utils.map.setup()
  Utils.discipline.setup()
  Utils.folds.setup()
  Utils.smart_nav.setup()
  require("utils.word_cycle").setup()
  Utils.action_manager.configure_group("Toggles", {
    title = "Toggles",
    icon = " ",
    columns = 3,
  })
  Utils.action_manager.configure_group("Git", {
    title = "Git",
    icon = "",
    columns = 2,
  })
  Utils.map.safe_keymap_set("n", "<leader>tu", Utils.action_manager.show_ui, {})
  require("utils.git").setup()
end, { group = "LazyModules" })
