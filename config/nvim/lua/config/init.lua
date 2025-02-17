-- TODO: remove deprecated

-- global variables
_G.Utils = require("utils")
_G.P = function(...)
  vim.print(vim.inspect(...))
end

------------------------------
-- Load modules
------------------------------
-- stylua: ignore start
local loaded        = 0
local failed        = {}
local total_modules = 0

local lazy_load = vim.fn.argc(-1) == 0
-- stylua: ignore end

------------------------------
-- Function to load a module
---@param module string
---@return boolean
------------------------------
local function load_module(module)
  total_modules = total_modules + 1
  local ok, err = pcall(require, "config." .. module)
  if ok then
    loaded = loaded + 1
  else
    failed[#failed + 1] = module
    vim.api.nvim_err_writeln(("Error loading module '%s': %s"):format(module, err))
  end
  return ok
end

------------------------------
-- Load Immediate Modules
------------------------------
load_module("globals")
load_module("options")
load_module("lazy")
if not lazy_load then
  load_module("autocmd") -- Load autocmd immediately if a file is opened
end

local group = vim.api.nvim_create_augroup("LazyModules", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "VeryLazy",
  callback = function()
    if lazy_load then
      load_module("autocmd")
    end
    load_module("keymaps")
    load_module("abbrevations")
  end,
})

------------------------------
-- Report any loading errors
------------------------------
if #failed > 0 then
  vim.notify(
    string.format("Loaded %d/%d modules. Failed: %s", loaded, total_modules, table.concat(failed, ", ")),
    vim.log.levels.WARN,
    { title = "Module Loading Summary" }
  )
end

Utils.ui.set_colorscheme("rose-pine")
Utils.ui.add_highlights({
  WinBar = {},
  WinBarNc = {},
})
