---@class utils.map
local M = setmetatable({}, {
  __call = function(m, mode, lhs, rhs, opts)
    return m.safe_keymap_set(mode, lhs, rhs, opts)
  end,
})
local wk_maps = {}
local did_setup = false
local deepcopy = vim.deepcopy

---------------------------------------------------------------
-- Validation functions
---@param mappings map.KeymapOpts
---@return boolean success
---------------------------------------------------------------
local function validate_keymap(mappings)
  if not mappings then return false end
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
-- Resolve single mapping or array of mappings to array
---@param mappings any
---@return table[]
---------------------------------------------------------------
local function resolve_mappings(mappings)
  if type(mappings) ~= "table" then return {} end
  -- Single mapping: has [1] as string, or has keys but no [1]
  if type(mappings[1]) == "string" or (mappings[1] == nil and next(mappings)) then return { mappings } end
  -- Array of mappings
  return mappings
end

---------------------------------------------------------------
-- Check if a mapping is a toggle mapping
---@param mapping table
---@return boolean
---------------------------------------------------------------
local function is_toggle_mapping(mapping)
  return vim.is_callable(mapping.get) and vim.is_callable(mapping.set)
end

---------------------------------------------------------------
-- copied from lazyvim
---Set a keymap safely, checking for lazy key handler conflicts
---@param mode map.KeymapMode|map.KeymapMode[] Mode or modes for the mapping
---@param lhs string Left-hand side of the mapping
---@param rhs string|function Right-hand side of the mapping
---@param opts? vim.keymap.set.Opts Additional options for the mapping
---@return boolean success Whether the mapping was set successfully
---------------------------------------------------------------
function M.safe_keymap_set(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  local modes = Utils.ensure_list(mode)

  for _, m in ipairs(modes) do
    if keys.have and keys:have(lhs, m) then return false end
  end

  opts = opts or {}
  opts.silent = opts.silent ~= false
  local ok = pcall(vim.keymap.set, modes, lhs, rhs, opts)
  return ok
end

---------------------------------------------------------------
-- Function to handle conditional mappings based on snippet session
---@param modes map.KeymapMode|map.KeymapMode[]
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
---@param opts? vim.keymap.set.Opts
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
-- Apply a single keymap
---@param mapping map.KeymapOpts
---------------------------------------------------------------
local function set_keymap(mapping)
  if vim.g.vscode then return end
  if not validate_keymap(mapping) then return end
  if mapping.lsp or mapping.has then
    local filter = mapping.lsp or {}
    Utils.lsp.on(filter, function(_, buf)
      local opts = Utils.lsp.map(mapping, buf)
      if opts then M.set(opts) end
    end)
    return
  end

  if mapping.conds then
    for _, condition in ipairs(Utils.ensure_list(mapping.conds)) do
      if not Utils.evaluate(condition) then return end
    end
  end
  local lhs, rhs = mapping[1], mapping[2]
  local mode = (mapping.mode and Utils.ensure_list(mapping.mode)) or { "n" }
  local opts = { desc = Utils.ensure_string(mapping.desc, "") }
  for _, field in ipairs({ "buffer", "silent", "remap", "expr" }) do
    if mapping[field] ~= nil then opts[field] = mapping[field] end
  end
  if not M.safe_keymap_set(mode, lhs, rhs, opts) then return end

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
---Set a single keymap with extended functionality
---@param mappings map.KeymapOpts|map.KeymapOpts[]
---------------------------------------------------------------
function M.set(mappings, opts)
  mappings = resolve_mappings(mappings)
  opts = opts or {}
  if #mappings == 0 then return end
  for _, map in ipairs(mappings) do
    local mapping = vim.tbl_deep_extend("force", {}, opts, map)
    if mapping.conds and map.conds then mapping.conds = vim.list_extend(vim.list_slice(opts.conds or {}), map.conds) end
    if is_toggle_mapping(mapping) then mapping = M.toggle(mapping) end
    set_keymap(mapping)
  end
end

----------------------------------------------------------------------
---@class map.Toggle
---@field mapping toggle.Opts
----------------------------------------------------------------------
local Toggle = {}
Toggle.__index = Toggle

---@param mapping toggle.Opts
---@return map.Toggle
function Toggle:new(mapping)
  return setmetatable({
    mapping = mapping,
    icons = {
      enabled = (mapping.icon and mapping.icon.enabled) or "  ",
      disabled = (mapping.icon and mapping.icon.disabled) or "  ",
    },
    color = {
      enabled = (mapping.color and mapping.color.enabled) or "green",
      disabled = (mapping.color and mapping.color.disabled) or "yellow",
    },
  }, Toggle)
end

function Toggle:notify(message, level, buf)
  buf = Utils.ensure_buf(buf)
  Utils.notify[level](message, { title = self.mapping.desc, buffer = buf })
end

function Toggle:is_valid()
  local m = self.mapping
  return type(m) == "table"
    and type(m[1]) == "string"
    and vim.is_callable(m.get)
    and vim.is_callable(m.set)
    and (m.notify == false or type(m.name) == "string")
end

---@param buf? number
function Toggle:get(buf)
  buf = Utils.ensure_buf(buf)
  local ok, ret = pcall(self.mapping.get, buf)
  if not ok then
    if not ok then
      self:notify({
        "Failed to get state for `" .. self.mapping.name .. "`:\n",
        ret,
      }, "warn")
    end
  end
  return ret
end

---@param state boolean
---@param buf? number
function Toggle:set(state, buf)
  buf = Utils.ensure_buf(buf)
  local ok, err = pcall(self.mapping.set, state, buf) ---@type boolean, string?
  if not ok then
    self:notify({
      "Failed to set state for `" .. self.mapping.name .. "`:\n",
      err,
    }, "error")
  end
end

-- notify
function Toggle:notification(buf)
  if self.mapping.notify == false then return end
  buf = Utils.ensure_buf(buf)
  local state = not self:get(buf)
  local name = self.mapping.name
  local msg = string.format("%s %s", state and "Disabled" or "Enabled", "**" .. name .. "**")
  local level = state and "warn" or "info"
  self:notify(msg, level)
end

-- toggle
---@param buf? number
function Toggle:toggle(buf)
  buf = Utils.ensure_buf(buf)
  local state = self:get(buf)
  self:set(state, buf)
  self:notification()
end

---Get description for the mapping
---@return string|function
function Toggle:desc()
  return function()
    local buf = Utils.ensure_buf()
    if Utils.type(self.mapping.desc, "function") then return self.mapping.desc(self:get(buf)) end
    return self.mapping.desc or string.format("Toggle %s", self.mapping.name)
  end
end

---Get icon
---@return fun(): table
function Toggle:icon()
  return function()
    local state = self:get()
    return {
      icon = state and self.icons.enabled or self.icons.disabled,
      color = state and self.color.enabled or self.color.disabled,
    }
  end
end

function Toggle:to_keymap()
  local map = {
    self.mapping[1],
    function()
      self:toggle(Utils.ensure_buf())
    end,
    mode = self.mapping.mode or "n",
    desc = self:desc(),
    icon = self:icon(),
  }
  local excluded = { "name", "get_state", "toggle_fn", "change_state", "color", "notify", "set_key", "get", "set" }
  for k, v in pairs(self.mapping) do
    if map[k] == nil and not vim.tbl_contains(excluded, k) then map[k] = v end
  end
  return map
end

---------------------------------------------------------------
---Create a toggle mapping
---@param mapping map.ToggleOpts
---@return map.KeymapOpts?
---------------------------------------------------------------
function M.toggle(mapping)
  local toggle = Toggle:new(mapping)
  if not toggle:is_valid() then return nil end
  local key = toggle:to_keymap()
  return key
end

local DEFAULT_ABBREV_CONDS = {
  -- disable abbreviations in comments and strings
  lsp_keyword = function()
    local ts = Utils.treesitter
    return ts.is_active() and not ts.find_node({ "comment", "string" })
  end,
}

-----------------------------------
-- Internal function to create a single abbreviation
---@param word string
---@param new_word string
---@param opts? map.AbbrevOpts
-----------------------------------
local function set_abbrev(word, new_word, opts)
  if not word or not new_word then return end
  opts = opts or {}
  local mode = opts.mode or "ia"
  local conds = Utils.ensure_list(opts.conds, false) or nil
  opts.conds = nil
  opts.mode = nil
  opts = vim.tbl_extend("force", opts or {}, {
    expr = true,
  })
  vim.keymap.set(mode, word, function()
    if conds then
      for _, c in ipairs(conds) do
        if Utils.type(c, "string") then
          if not DEFAULT_ABBREV_CONDS[c] then return word end
          c = DEFAULT_ABBREV_CONDS[c]
        end
        if Utils.type(c, "function") then
          if not Utils.evaluate(c, true) then return word end
        end
      end
    end
    return new_word
  end, opts)
end

---------------------------------------------------------------
---Create multiple abbreviations with shared options
---@param abbrevs map.Abbrevs[]
---@param opts? map.AbbrevOpts
---------------------------------------------------------------
function M.abbrev(abbrevs, opts)
  if type(abbrevs) ~= "table" then return end
  opts = opts or {}
  for _, abbrev in ipairs(abbrevs) do
    local right_word = abbrev[1]
    local wrong_words = Utils.ensure_list(abbrev[2])
    local abbrev_opts = abbrev[3] or {}
    local merged_opts = vim.tbl_deep_extend("force", {}, opts, abbrev_opts)
    for _, wrong_word in ipairs(wrong_words) do
      if type(wrong_word) == "string" then set_abbrev(wrong_word, right_word, merged_opts) end
    end
  end
end

-----------------------------------
-- Internal function to delete a single keymap
---@param mapping table|string
-----------------------------------
local function del_keymap(mapping)
  if type(mapping) == "string" then mapping = { [1] = mapping } end
  local lhs = mapping[1]
  if not lhs then return end
  local modes = mapping.mode and Utils.ensure_list(mapping.mode) or { "n" }
  local opts = {}
  if mapping.buffer ~= nil then opts.buffer = mapping.buffer end
  pcall(vim.keymap.del, modes, lhs, opts)
  if mapping.icon then M.hide_from_wk({
    { lhs, mode = modes, buffer = mapping.buffer },
  }) end
end

---------------------------------------------------------------
---Delete keymap(s) - handles single or multiple
---@param mappings (map.KeymapOpts|string)|table[] Single mapping or array
---@param opts? map.KeymapOpts Shared options for all mappings
---------------------------------------------------------------
function M.del(mappings, opts)
  mappings = resolve_mappings(mappings)
  opts = opts or {}

  for _, map in ipairs(mappings) do
    local mapping = type(map) == "string" and { [1] = map } or map
    local merged = vim.tbl_deep_extend("force", {}, opts, mapping)
    del_keymap(merged)
  end
end

---------------------------------------------------------------
---Add mappings to which-key without setting them
---@param mappings wk.Spec|wk.Spec[] # Which-key mapping definitions
---------------------------------------------------------------
function M.add_to_wk(mappings)
  if type(mappings) ~= "table" then return end
  if type(mappings[1]) ~= "table" then mappings = { mappings } end
  for _, map in ipairs(mappings) do
    if type(map) == "table" then table.insert(wk_maps, map) end
  end
  if did_setup then Utils.autocmd.exec_user_event("KeymapSet") end
end

---------------------------------------------------------------
-- Hide mappings in which-key window
---@param mappings wk.Spec|wk.Spec[] # Which-key mapping definitions
---------------------------------------------------------------
function M.hide_from_wk(mappings)
  if type(mappings) ~= "table" then return end

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
  local key = opts.key or "<leader>rr"
  opts.key = nil
  if opts.cond ~= nil and not opts.cond then return end
  if not opts.cmd then
    Utils.notify.error("No command provided to reload config")
    return
  end

  if opts.restart then
    local process = opts.title:lower()
    local is_running = Utils.run_command({ "pgrep", "-x", process })
    local is_exec = Utils.is_executable(process)
    if not is_running or not is_exec then return end
  end

  local function build_cmd()
    local cmd = opts.cmd
    if opts.restart then
      cmd = vim.fn.shellescape(cmd)
      local process = opts.title:lower()
      return string.format("pkill -x %s || true; nohup %s > /dev/null 2>&1 & disown", process, cmd)
    end
    return string.format("nohup %s > /dev/null 2>&1 & disown", cmd)
  end

  M.set({
    key,
    function()
      local cmd = build_cmd()
      local success, output = Utils.run_command(cmd, { trim = true })
      local notify_opts = {
        title = opts.title,
        timeout = success and 2000 or 5000,
      }
      local status = success and "Success" or "Error"
      local action = opts.restart and "Restarting" or "Reloading"
      local msg
      if not success then
        msg = string.format("%s %s %s: %s", status, action, opts.title, output)
      else
        msg = string.format("%s %s %s", status, action, opts.title)
      end
      Utils.notify[success and "info" or "warn"](msg, notify_opts)
      Utils.ui.refresh()
    end,
    desc = "Reload Config",
    silent = true,
    buffer = opts.buffer or true,
    icon = { icon = opts.restart and "󰜉 " or "󰑓 ", color = "orange" },
  })
end

---------------------------------------------------------------
---Apply which-key mappings if available
---------------------------------------------------------------
function M._apply_which_key()
  if #wk_maps > 0 and Utils.is_loaded("which-key.nvim") then
    local wk = require("which-key")
    local current_maps = deepcopy(wk_maps)
    wk_maps = {}
    wk.add(current_maps)
  end
end

M.setup = function()
  Utils.on_load("which-key.nvim", function()
    M._apply_which_key()
    did_setup = true

    Utils.autocmd.on_user_event("KeymapSet", function()
      M._apply_which_key()
    end)
  end)
end

return M
