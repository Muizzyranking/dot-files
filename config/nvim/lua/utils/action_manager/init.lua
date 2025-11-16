---@class utils.action_manager
---@field registry utils.action_manager.registry
---@field ui utils.action_manager.ui
local M = {}
setmetatable(M, {
  __index = function(t, k)
    t[k] = require("utils.action_manager." .. k)
    return t[k]
  end,
})

---Register an item to a group (creates group if doesn't exist)
---@param group_name string
---@param item ActionManager.Item Item configuration
function M.register_item(group_name, item)
  M.registry.register_item(group_name, item)
end

---Configure a group's display settings
---@param group_name string
---@param config table Group configuration {columns?, icon?, title?, keymaps?, footer?}
function M.configure_group(group_name, config)
  M.registry.configure_group(group_name, config)
end

---Show UI - either group selector or specific group
---@param opts table
function M.show_ui(opts)
  opts = opts or {}
  local group_name = opts and opts.group_name
  opts.group_name = nil
  if group_name then
    M.ui.show_group_ui(group_name, opts)
  else
    M.ui.show_selector_ui(opts)
  end
end

---Toggle UI (close if open, show if closed)
---@param opts? table
function M.toggle_ui(opts)
  if M.ui.is_open() then
    M.ui.close_ui()
  else
    M.show_ui(opts)
  end
end

---@return table
function M.get_groups()
  return M.registry.get_groups()
end

return M
