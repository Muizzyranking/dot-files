------------------------------
-- List of modules to load
------------------------------
local modules = {
  "options",
  "keymaps",
  "autocmd",
  "lazy",
  "abbrevations",
}

------------------------------
-- Function to load a module
---@param module string
---@return boolean
------------------------------
local function load_module(module)
  local ok, err = pcall(require, "config." .. module)
  if not ok then
    vim.notify(
      string.format("Error loading module '%s': %s", module, err),
      vim.log.levels.ERROR,
      { title = "Module Loading Error" }
    )
    return false
  end
  return true
end

------------------------------
-- Counters for loaded and failed modules
------------------------------
local loaded_modules = 0
local failed_modules = {}

------------------------------
-- safely load modules and track their status.
------------------------------
for _, module in ipairs(modules) do
  if load_module(module) then
    loaded_modules = loaded_modules + 1
  else
    table.insert(failed_modules, module)
  end
end

------------------------------
-- Notify about the overall loading status
------------------------------
if #failed_modules > 0 then
  vim.notify(
    string.format(
      "Loaded %d/%d modules. Failed modules: %s",
      loaded_modules,
      #modules,
      table.concat(failed_modules, ", ")
    ),
    vim.log.levels.WARN,
    { title = "Module Loading Summary" }
  )
end

------------------------------
-- Set the colorscheme
------------------------------
vim.cmd("colorscheme rose-pine")
