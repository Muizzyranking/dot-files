---@class utils.map
local M = setmetatable({}, {
  __call = function(m, mode, lhs, rhs, opts)
    return m.safe_keymap_set(mode, lhs, rhs, opts)
  end,
})
M._wk_maps = {}
M._is_setup = false
local api = vim.api
local tbl_contains = vim.tbl_contains
local deepcopy = vim.deepcopy

local function is_debug()
  return vim.g.keymap_debug == true
end

---------------------------------------------------------------
-- Validation functions
---@param mapping map.KeymapOpts
---@return boolean success
---@return string? error
---------------------------------------------------------------
local function validate_keymap(mapping)
  if
    type(mapping) ~= "table"
    or type(mapping[1]) ~= "string"
    or (type(mapping[2]) ~= "string" and type(mapping[2]) ~= "function")
  then
    return false, "Invalid keymap: missing or invalid lhs/rhs"
  end

  if mapping.mode then
    local valid_modes = { "n", "i", "v", "x", "s", "o", "t", "c" }
    local modes = type(mapping.mode) == "string" and { mapping.mode } or mapping.mode or { "n" }

    for _, mode in ipairs(modes) do
      if not tbl_contains(valid_modes, mode) then
        return false, string.format("Invalid mode: %s", mode)
      end
    end
  end

  return true, nil
end

---------------------------------------------------------------
---@param opts map.ToggleOpts
---@return boolean success
---@return string? error
---------------------------------------------------------------
local function is_toggle_opts(opts)
  if type(opts) ~= "table" or not opts.get_state or (not opts.change_state and not opts.toggle_fn) then
    return false, "Toggle map requires get_state and change_state/toggle_fn functions"
  end
  return true, nil
end

---------------------------------------------------------------
---Set a keymap safely, checking for lazy key handler conflicts
---@param mode KeymapMode|KeymapMode[] Mode or modes for the mapping
---@param lhs string Left-hand side of the mapping
---@param rhs string|function Right-hand side of the mapping
---@param opts? table Additional options for the mapping
---@return boolean success Whether the mapping was set successfully
---------------------------------------------------------------
function M.safe_keymap_set(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  local modes = type(mode) == "string" and { mode } or mode

  -- Check for ANY lazy handler
  for _, m in ipairs(modes) do
    if keys.have and keys:have(lhs, m) then
      if is_debug() then
        error(string.format("Lazy handler exists for mapping %s in mode %s", lhs, m))
      end
      return false
    end
  end

  -- No lazy handlers found, safe to set
  opts = opts or {}
  opts.silent = opts.silent ~= false
  local ok, err = pcall(vim.keymap.set, modes, lhs, rhs, opts)
  if not ok and is_debug() then
    error(string.format("Failed to set keymap: %s", err))
  end
  return ok
end

---------------------------------------------------------------
---Set a single keymap with extended functionality
---@param mapping map.KeymapOpts
---@return boolean success
---------------------------------------------------------------
function M.set_keymap(mapping)
  local ok, err = validate_keymap(mapping)
  if not ok then
    if is_debug() then
      error(err)
    end
    return false
  end

  local lhs, rhs = mapping[1], mapping[2]
  local mode = (type(mapping.mode) == "string" and { mapping.mode } or mapping.mode) or { "n" }

  local opts = {
    desc = type(mapping.desc) == "function" and mapping.desc() or (mapping.desc or ""),
  }

  for _, field in ipairs({ "buffer", "silent", "remap", "expr" }) do
    if mapping[field] ~= nil then
      opts[field] = mapping[field]
    end
  end

  if not M.safe_keymap_set(mode, lhs, rhs, opts) then
    return false
  end

  if mapping.icon then
    M.add_to_wk({
      {
        lhs = lhs,
        mode = mode,
        icon = mapping.icon,
        desc = mapping.desc or "",
      },
    })
  end

  return true
end

---@param mappings map.KeymapOpts[] Keymap options
---@return boolean success
function M.set_keymaps(mappings)
  if type(mappings) ~= "table" then
    if is_debug() then
      error("Invalid keymap options: must be a table")
    end
    return false
  end
  if type(mappings[1]) ~= "table" then
    mappings = { mappings }
  end
  for i, map in ipairs(mappings) do
    local ok, err = validate_keymap(map)
    if not ok and is_debug() then
      error(string.format("Invalid keymap at index %d: %s", i, err))
    end
    M.set_keymap(map)
  end
  return true
end

---------------------------------------------------------------
---Create a toggle mapping
---@param opts map.ToggleOpts
---@return boolean|table success or mapping table if set_key is false
---------------------------------------------------------------
function M.toggle_map(opts)
  local ok, err = is_toggle_opts(opts)
  if not ok then
    if is_debug() then
      error(err)
    end
    return false
  end

  local mapping = {
    opts[1],
    opts.toggle_fn or function()
      opts.change_state(opts.get_state())
      if opts.notify ~= false then
        Utils.notify[opts.get_state() and "info" or "warn"](
          ("%s %s"):format(opts.get_state() and "Enabled" or "Disabled", opts.name),
          { title = opts.name }
        )
      end
    end,
    mode = opts.mode or "n",
    desc = type(opts.desc) == "function" and function()
      return opts.desc(opts.get_state())
    end or opts.desc or ("Toggle %s"):format(opts.name),
    icon = function()
      local state = opts.get_state()
      local icon = opts.icon or {}
      local color = opts.color or {}
      return {
        icon = state and (icon.enabled or "  ") or (icon.disabled or " "),
        color = state and (color.enabled or "green") or (color.disabled or "yellow"),
      }
    end,
  }

  for k, v in pairs(opts) do
    if mapping[k] == nil then
      mapping[k] = v
    end
  end

  for _, field in ipairs({
    "name",
    "get_state",
    "toggle_fn",
    "change_state",
    "color",
    "notify",
    "set_key",
  }) do
    mapping[field] = nil
  end

  if opts.set_key ~= false then
    return M.set_keymap(mapping)
  end

  return mapping
end

---------------------------------------------------------------
---Create multiple toggle mappings
---@param mappings map.ToggleOpts[]
---@return boolean|table[] success or mapping tables
---------------------------------------------------------------
function M.toggle_maps(mappings)
  local results = {}
  for i, map in ipairs(mappings) do
    local ok, err = is_toggle_opts(map)
    if not ok then
      if is_debug() then
        error(string.format("Invalid toggle map at index %d: %s", i, err))
      end
      return false
    end
    results[i] = M.toggle_map(map)
  end
  return results
end

---------------------------------------------------------------
---Add mappings to which-key without setting them
---@param mappings table|table[] Which-key mapping definitions
---@return boolean success
---------------------------------------------------------------
function M.add_to_wk(mappings)
  if type(mappings) ~= "table" then
    if is_debug() then
      error("Invalid which-key options: must be a table")
    end
    return false
  end
  if type(mappings[1]) ~= "table" then
    mappings = { mappings }
  end
  for _, map in ipairs(mappings) do
    if type(map) == "table" then
      table.insert(M._wk_maps, map)
    end
  end
  if M._is_setup then
    api.nvim_exec_autocmds("User", {
      pattern = "KeymapSet",
      data = {
        has_icon = true,
      },
    })
  end
  return true
end

---------------------------------------------------------------
---Apply which-key mappings if available
---------------------------------------------------------------
function M._apply_which_key()
  if #M._wk_maps > 0 and Utils.is_loaded("which-key.nvim") then
    local wk = require("which-key")
    local current_maps = deepcopy(M._wk_maps)
    M._wk_maps = {}
    wk.add(current_maps)
  end
end

api.nvim_create_autocmd("User", {
  pattern = "KeymapSet",
  callback = function(event)
    if event.data.has_icon then
      M._apply_which_key()
    end
  end,
})

Utils.on_load("which-key.nvim", function()
  M._apply_which_key()
  M._is_setup = true
end)

return M
