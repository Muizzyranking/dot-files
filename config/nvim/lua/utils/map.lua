---@class utils.map
local M = setmetatable({}, {
  __call = function(m, mode, lhs, rhs, opts)
    return m.safe_keymap_set(mode, lhs, rhs, opts)
  end,
})
M._wk_maps = {}
M._is_setup = false
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
  local modes = Utils.ensure_list(mode)

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
-- Function to handle conditional mappings based on snippet session
---@param modes table|string
---@param lhs string
---@param rhs string
---@param opts table
---------------------------------------------------------------
function M.snippet_aware_map(modes, lhs, rhs, opts)
  opts = opts or {}
  opts.expr = true

  M.safe_keymap_set(modes, lhs, function()
    if Utils.cmp.in_snippet_session() then
      return lhs
    else
      return rhs
    end
  end, opts)
end

---------------------------------------------------------------
-- auto indent
---@param keys string[]|string
---@param opts? table
---------------------------------------------------------------
function M.auto_indent(keys, opts)
  keys = keys and Utils.ensure_list(keys) or Utils.ensure_list({ "i" })
  opts = opts or {}
  opts.expr = true
  opts.desc = opts.desc or "Auto-indent on insert enter"
  for _, key in ipairs(keys) do
    if Utils.type(key, "string") then
      M.safe_keymap_set("n", key, function()
        return not vim.api.nvim_get_current_line():match("%g") and '"_cc' or key
      end, opts)
    end
  end
end

---------------------------------------------------------------
---Set a single keymap with extended functionality
---@param mapping map.KeymapOpts
---------------------------------------------------------------
function M.set_keymap(mapping)
  if vim.g.vscode then
    return
  end

  if not validate_keymap(mapping) then
    return
  end

  if mapping.conds then
    local conditions = Utils.ensure_list(mapping.conds)
    for _, condition in ipairs(conditions) do
      if not Utils.evaluate(condition) then
        return
      end
    end
  end

  local lhs, rhs = mapping[1], mapping[2]
  local mode = (mapping.mode and Utils.ensure_list(mapping.mode)) or { "n" }

  local opts = {
    desc = Utils.ensure_string(mapping.desc, ""),
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
        lhs,
        mode = mode,
        icon = mapping.icon,
        desc = mapping.desc or "",
        buffer = mapping.buffer,
      },
    })
  end
end

---------------------------------------------------------------
---@param mappings map.KeymapOpts[] # Keymap options
---@param opts? map.KeymapOpts #  Shared options for all mappings
---------------------------------------------------------------
function M.set_keymaps(mappings, opts)
  if type(mappings) ~= "table" then
    return
  end
  if type(mappings[1]) ~= "table" then
    mappings = { mappings }
  end
  opts = opts or {}
  for _, map in ipairs(mappings) do
    local new_map = vim.tbl_deep_extend("force", {}, opts, map)
    M.set_keymap(new_map)
  end
end

----------------------------------------------------------------------
---@class Toggle
---@field mapping map.ToggleOpts
---@field buf number
---@field state boolean
----------------------------------------------------------------------
local Toggle = {}
Toggle.__index = Toggle

---@param mapping map.ToggleOpts
---@return Toggle
function Toggle:new(mapping)
  self = setmetatable({}, Toggle)
  self.mapping = mapping
  self:refresh()
  return self
end

function Toggle:is_toggle_opts()
  local mapping = self.mapping
  return type(mapping) == "table"
    and type(mapping[1]) == "string"
    and vim.is_callable(mapping.get_state)
    and vim.is_callable(mapping.change_state)
    and (mapping.notify == false or type(mapping.name) == "string")
end

---Refresh current buffer and state
function Toggle:refresh()
  self.buf = Utils.ensure_buf(self.mapping.buffer or 0)
  self.state = self.mapping.get_state(self.buf)
end

-- notify
function Toggle:notify()
  if self.mapping.notify ~= false then
    local state, name = self.state, self.mapping.name
    local msg = string.format("%s %s", state and "Disabled" or "Enabled", name)
    local level = state and "warn" or "info"
    Utils.notify[level](msg, { title = name })
  end
end

-- toggle
function Toggle:toggle()
  self:refresh()
  self.mapping.change_state(self.state, self.buf)
  self:notify()
end

---Get description for the mapping
---@return string|function
function Toggle:desc()
  if Utils.type(self.mapping.desc, "function") then
    return function()
      self:refresh()
      return self.mapping.desc(self.state)
    end
  end
  return self.mapping.desc or string.format("Toggle %s", self.mapping.name)
end

---Get icon
---@return fun(): table
function Toggle:icon()
  return function()
    self:refresh()
    local icon = self.mapping.icon or {}
    local color = self.mapping.color or {}
    local state = self.state
    return {
      icon = state and (icon.enabled or "  ") or (icon.disabled or "  "),
      color = state and (color.enabled or "green") or (color.disabled or "yellow"),
    }
  end
end

---------------------------------------------------------------
---Create a toggle mapping
---@param mapping map.ToggleOpts
---@return map.KeymapOpts?
---------------------------------------------------------------
function M.toggle_map(mapping)
  local toggle = Toggle:new(mapping)
  if not toggle:is_toggle_opts() then
    return
  end

  local map = {
    mapping[1],
    function()
      toggle:toggle()
    end,
    mode = mapping.mode or "n",
    desc = toggle:desc(),
    icon = toggle:icon(),
  }

  local excluded = { "name", "get_state", "toggle_fn", "change_state", "color", "notify", "set_key" }
  for k, v in pairs(mapping) do
    if map[k] == nil and not vim.tbl_contains(excluded, k) then
      map[k] = v
    end
  end

  if mapping.set_key ~= false then
    M.set_keymap(map)
    return
  end
  return map
end

---------------------------------------------------------------
---Create multiple toggle mappings
---@param mappings map.ToggleOpts[]
---@return table[]? # success or mapping tables
---------------------------------------------------------------
function M.toggle_maps(mappings, opts)
  if type(mappings) ~= "table" then
    return nil
  end
  local results = {}
  opts = opts or {}
  for _, map in ipairs(mappings) do
    local merged_opts = vim.tbl_deep_extend("force", {}, opts, map)
    local result = M.toggle_map(merged_opts)
    if result then
      table.insert(results, result)
    end
  end
  return #results > 0 and results or nil
end

local DEFAULT_ABBREV_CONDS = {
  -- disable abbreviations in comments and strings
  lsp_keyword = function()
    return Utils.ts.is_active() and not Utils.ts.find_node({ "comment", "string" })
  end,
}

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
  local mode = opts.mode or "ia"
  local conds = Utils.ensure_list(opts.conds) or nil
  opts.conds = nil
  opts.condition = nil
  opts.mode = nil
  opts = vim.tbl_extend("force", opts or {}, {
    expr = true,
  })
  vim.keymap.set(mode, word, function()
    if conds then
      for _, c in ipairs(conds) do
        if Utils.type(c, "string") then
          if not DEFAULT_ABBREV_CONDS[c] then
            return word
          end
          c = DEFAULT_ABBREV_CONDS[c]
        end
        if Utils.type(c, "function") then
          if not Utils.evaluate(c, true) then
            return word
          end
        end
      end
    end
    return new_word
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
---@param mappings wk.Spec # Which-key mapping definitions
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
    Utils.autocmd.exec_user_event("KeymapSet")
  end
end

---------------------------------------------------------------
-- Hide mappings in which-key window
---@param mappings wk.Spec # Which-key mapping definitions
---------------------------------------------------------------
function M.hide_from_wk(mappings)
  if type(mappings) ~= "table" then
    return
  end

  for _, map in ipairs(mappings) do
    if type(map) == "string" then
      mappings[_] = {
        [1] = map,
        hidden = true,
      }
    elseif type(map) == "table" then
      map.hidden = true
    end
  end

  M.add_to_wk(mappings)
end

-----------------------------------
-- reloads configs e.g kitty
---@param opts map.ReloadConfig
-----------------------------------
function M.reload_config(opts)
  opts = opts or {}
  opts.buffer = Utils.ensure_buf(opts.buffer)
  opts.title = opts.title or "Config"
  if opts.cond ~= nil and not opts.cond then
    return
  end
  if not opts.cmd then
    Utils.notify.error("No command provided to reload config")
    return
  end

  if opts.restart then
    local process = opts.title:lower()
    local is_running = vim.fn.system("pgrep -x " .. process) ~= ""
    local is_exec = Utils.is_executable(process)
    if not is_running or not is_exec then
      return
    end
  end
  -- Determine the command to execute

  local function build_cmd()
    local cmd = vim.fn.shellescape(opts.cmd)
    if opts.restart then
      local process = opts.title:lower()
      return string.format("pkill -x %s || true; nohup %s > /dev/null 2>&1 & disown", process, cmd)
    end
    return string.format("nohup %s > /dev/null 2>&1 & disown", cmd)
  end

  M.set_keymap({
    "<leader>rr",
    function()
      local cmd = build_cmd()
      local output = vim.fn.system(cmd)
      local has_error = vim.v.shell_error ~= 0
      local notify_opts = {
        title = opts.title,
        timeout = has_error and 5000 or 2000,
      }
      local status = has_error and "Error" or "Success"
      local action = opts.restart and "Restarting" or "Reloading"
      local msg
      if has_error then
        local clean_output = output:gsub("\n", " ")
        msg = string.format("%s %s %s: %s", status, action, opts.title, clean_output)
      else
        msg = string.format("%s %s %s", status, action, opts.title)
      end
      Utils.notify[has_error and "error" or "info"](msg, notify_opts)
      Utils.ui.refresh()
    end,
    desc = "Reload Config",
    silent = true,
    buffer = opts.buffer,
    icon = { icon = opts.restart and "󰜉 " or "󰑓 ", color = "orange" },
  })
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

M.setup = function()
  Utils.on_load("which-key.nvim", function()
    M._apply_which_key()
    M._is_setup = true

    Utils.autocmd.on_user_event("KeymapSet", function()
      M._apply_which_key()
    end)
  end)
end

return M
