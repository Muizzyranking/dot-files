---@class utils.action_manager.registry
local M = {}

M._registry = {}

M._config = {
  default_columns = 2,
}

---------------------------------------------------------------
-- Get default group configuration
---------------------------------------------------------------
local function get_default_group_config(group_name)
  local title = group_name:gsub("^%l", string.upper):gsub("_", " ")
  return {
    columns = M._config.default_columns,
    icon = "●",
    title = title,
    keymaps = {},
    footer = nil,
  }
end

---------------------------------------------------------------
-- Ensure group exists
---------------------------------------------------------------
local function ensure_group(group_name)
  if not M._registry[group_name] then
    M._registry[group_name] = {
      config = get_default_group_config(group_name),
      items = {},
    }
  end
end

---------------------------------------------------------------
-- Register an item to a group
---@param group_name string
---@param item table
---------------------------------------------------------------
function M.register_item(group_name, item)
  ensure_group(group_name)
  local items = M._registry[group_name].items

  for i, existing in ipairs(items) do
    local is_duplicate = false
    if existing.type == "toggle" and item.type == "toggle" then
      is_duplicate = existing.toggle == item.toggle
    elseif existing.name == item.name then
      is_duplicate = true
    end

    if is_duplicate then
      items[i] = item
      return
    end
  end

  table.insert(items, item)
end

---------------------------------------------------------------
---@param mapping map.KeymapOpts Keymap mapping configuration
---@return boolean should_register
---@return string|nil group_name The group name to register to (if should register)
---------------------------------------------------------------
function M.should_register_to_ui(mapping)
  if mapping.ui == false then return false, nil end

  if mapping.ui == true then
    local group = mapping._is_toggle and "Toggles" or "Actions"
    return true, group
  end

  if type(mapping.ui) == "table" then
    if mapping.ui.register == false then return false, nil end
    local group = mapping.ui.group
    if not group then group = mapping._is_toggle and "Toggles" or "Actions" end
    return true, group
  end

  if mapping._is_toggle then return true, "Toggles" end

  return false, nil
end

---------------------------------------------------------------
-- Helper: Register a keymap to UI (called from set_keymap)
---@param mapping table Keymap mapping configuration
---@param rhs string|function Right-hand side of the mapping
---@return boolean success Whether registration succeeded
---------------------------------------------------------------
function M.register_keymap_to_ui(mapping, rhs)
  local should_register, group_name = M.should_register_to_ui(mapping)
  if not should_register then return false end
  if mapping._is_toggle and group_name == "Toggles" then return false end

  local icon_data = mapping.icon
  if type(icon_data) == "function" then icon_data = icon_data() end

  local name = mapping.name or mapping.desc or "Unknown"
  if Utils.type(name, "function") then name = name() end

  if mapping._is_toggle and mapping._toggle_instance then
    local toggle = mapping._toggle_instance
    M.register_item(group_name, {
      type = "toggle",
      name = name,
      icon = icon_data,
      state = toggle.state,
      toggle = toggle,
    })
    return true
  end

  if type(rhs) ~= "function" then return false end
  M.register_item(group_name, {
    type = "action",
    name = name,
    icon = icon_data,
    execute = function(buf)
      rhs(buf)
    end,
  })
  return true
end

---------------------------------------------------------------
-- Configure a group
---@param group_name string
---@param config table
---------------------------------------------------------------
function M.configure_group(group_name, config)
  ensure_group(group_name)
  M._registry[group_name].config = vim.tbl_deep_extend("force", M._registry[group_name].config, config)
end

---------------------------------------------------------------
-- Get all groups
---@return table<string, {config: table, items: table[]}>
---------------------------------------------------------------
function M.get_groups()
  return M._registry
end

---------------------------------------------------------------
-- Get group configuration
---@param group_name string
---@return table?
---------------------------------------------------------------
function M.get_group_config(group_name)
  local group = M._registry[group_name]
  return group and group.config
end

---------------------------------------------------------------
-- Get items in a group
---@param group_name string
---@return table[]
---------------------------------------------------------------
function M.get_group_items(group_name)
  local group = M._registry[group_name]
  return group and group.items or {}
end

---------------------------------------------------------------
-- Get group count
---@return number
---------------------------------------------------------------
function M.get_group_count()
  local count = 0
  for _ in pairs(M._registry) do
    count = count + 1
  end
  return count
end

---------------------------------------------------------------
-- Get item count in group
---@param group_name string
---@return number
---------------------------------------------------------------
function M.get_item_count(group_name)
  local items = M.get_group_items(group_name)
  return #items
end

return M
