---@class utils.map
local M = setmetatable({}, {
  __call = function(m, mode, lhs, rhs, opts)
    return m.safe_keymap_set(mode, lhs, rhs, opts)
  end,
})
M._wk_maps = {}
M._is_setup = false
local api = vim.api
local deepcopy = vim.deepcopy

---------------------------------------------------------------
-- Validation functions
---@param mappings map.KeymapOpts
---@return boolean success
---------------------------------------------------------------
local function validate_keymap(mappings)
  if not mappings then
    return false
  end
  if
    type(mappings) ~= "table"
    or type(mappings[1]) ~= "string"
    or (type(mappings[2]) ~= "string" and type(mappings[2]) ~= "function")
  then
    return false
  end
  return true
end

---------------------------------------------------------------
---@param opts map.ToggleOpts
---@return boolean success
---------------------------------------------------------------
local function is_toggle_opts(opts)
  if type(opts) ~= "table" or not opts.get_state or (not opts.change_state and not opts.toggle_fn) then
    return false
  end
  return true
end

---------------------------------------------------------------
-- copied from lazyvim
---Set a keymap safely, checking for lazy key handler conflicts
---@param mode KeymapMode|KeymapMode[] Mode or modes for the mapping
---@param lhs string Left-hand side of the mapping
---@param rhs string|function Right-hand side of the mapping
---@param opts? table Additional options for the mapping
---@return boolean success Whether the mapping was set successfully
---------------------------------------------------------------
function M.safe_keymap_set(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  local modes = type(mode) == "string" and { mode } or mode

  for _, m in ipairs(modes) do
    if keys.have and keys:have(lhs, m) then
      return false
    end
  end

  opts = opts or {}
  opts.silent = opts.silent ~= false
  local ok = pcall(vim.keymap.set, modes, lhs, rhs, opts)
  return ok
end

---------------------------------------------------------------
---Set a single keymap with extended functionality
---@param mapping map.KeymapOpts
---------------------------------------------------------------
function M.set_keymap(mapping)
  local ok = validate_keymap(mapping)
  if not ok then
    return
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
    return
  end

  if mapping.icon then
    M.add_to_wk({
      {
        lhs = lhs,
        mode = mode,
        icon = mapping.icon,
        desc = mapping.desc or "",
        buffer = mapping.buffer,
      },
    })
  end
end

---@param mappings map.KeymapOpts[] # Keymap options
function M.set_keymaps(mappings)
  if type(mappings) ~= "table" then
    return
  end
  if type(mappings[1]) ~= "table" then
    mappings = { mappings }
  end
  for _, map in ipairs(mappings) do
    M.set_keymap(map)
  end
end

---------------------------------------------------------------
---Create a toggle mapping
---@param opts map.ToggleOpts
---------------------------------------------------------------
function M.toggle_map(opts)
  local ok = is_toggle_opts(opts)
  if not ok then
    return
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
    M.set_keymap(mapping)
  end

  return mapping
end

---------------------------------------------------------------
---Create multiple toggle mappings
---@param mappings map.ToggleOpts[]
---@return table[]|nil # success or mapping tables
---------------------------------------------------------------
function M.toggle_maps(mappings)
  local results = {}
  for _, map in ipairs(mappings) do
    table.insert(results, M.toggle_map(map))
  end
  return #results > 0 and results or nil
end

-----------------------------------
-- create abbreviations
---@param word string
---@param new_word string
---@param opts table
-----------------------------------
function M.create_abbrev(word, new_word, opts)
  if not word or not new_word then
    return
  end
  opts = opts or {}
  local condition = opts.condition
  opts.condition = nil
  local mode = opts.mode or "ia"
  opts.mode = nil
  opts = vim.tbl_extend("force", opts or {}, {
    expr = true,
  })
  vim.keymap.set(mode, word, function()
    local cond = not condition or (type(condition) == "function" and condition())
    if cond then
      return new_word
    end
    return word
  end, opts)
end

---------------------------------------------------------------
---Create multiple abbreviations with shared options
---@param abbrevs table[] # List of abbreviation pairs {word, new_word} or {word, new_word, opts}
---@param opts? table # Shared options for all abbreviations
---------------------------------------------------------------
function M.create_abbrevs(abbrevs, opts)
  if type(abbrevs) ~= "table" then
    return
  end

  opts = opts or {}

  for _, abbrev in ipairs(abbrevs) do
    local word = abbrev[1]
    local new_word = abbrev[2]
    local abbrev_opts = abbrev[3] or {}

    local merged_opts = vim.tbl_deep_extend("force", {}, opts, abbrev_opts)

    M.create_abbrev(word, new_word, merged_opts)
  end
end

---------------------------------------------------------------
---Add mappings to which-key without setting them
---@param mappings table|table[] Which-key mapping definitions
---------------------------------------------------------------
function M.add_to_wk(mappings)
  if type(mappings) ~= "table" then
    return
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
      data = { has_icon = true },
    })
  end
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
