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

-- Function to handle conditional mappings based on snippet session
---@param modes table|string
---@param lhs string
---@param rhs string
---@param opts table
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

---------------------------------------------------------------
---@param mappings map.KeymapOpts[] # Keymap options
---@param opts? table #  Shared options for all mappings
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

---------------------------------------------------------------
---Create a toggle mapping
---@param mapping map.ToggleOpts
---------------------------------------------------------------
function M.toggle_map(mapping)
  local ok = is_toggle_opts(mapping)
  if not ok then
    return
  end
  local map = {
    mapping[1],
    mapping.toggle_fn or function()
      mapping.change_state(mapping.get_state())
      if mapping.notify ~= false then
        Utils.notify[mapping.get_state() and "info" or "warn"](
          ("%s %s"):format(mapping.get_state() and "Enabled" or "Disabled", mapping.name),
          { title = mapping.name }
        )
      end
    end,
    mode = mapping.mode or "n",
    desc = type(mapping.desc) == "function" and function()
      return mapping.desc(mapping.get_state())
    end or mapping.desc or ("Toggle %s"):format(mapping.name),
    icon = function()
      local state = mapping.get_state()
      local icon = mapping.icon or {}
      local color = mapping.color or {}
      return {
        icon = state and (icon.enabled or "  ") or (icon.disabled or " "),
        color = state and (color.enabled or "green") or (color.disabled or "yellow"),
      }
    end,
  }

  for k, v in pairs(mapping) do
    if map[k] == nil then
      map[k] = v
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
    map[field] = nil
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
---@return table[]|nil # success or mapping tables
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
  local condition = opts.condition
  local mode = opts.mode or "ia"
  local builtin = opts.builtin
  opts.builtin = nil
  opts.condition = nil
  opts.mode = nil
  opts = vim.tbl_extend("force", opts or {}, {
    expr = true,
  })
  vim.keymap.set(mode, word, function()
    local cond = true
    if builtin then
      local built_in_fn = DEFAULT_ABBREV_CONDS[builtin]
      if built_in_fn then
        cond = built_in_fn()
      end
    end

    -- Combine with custom condition
    if condition then
      cond = cond and condition()
    end
    return cond and new_word or word
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

-----------------------------------
-- reloads configs e.g kitty
---@param opts table
-----------------------------------
function M.reload_config(opts)
  opts = opts or {}
  opts.buffer = opts.buffer or vim.api.nvim_get_current_buf()
  opts.title = opts.title or "Config"
  if opts.cond ~= nil and not opts.cond then
    return
  end
  if not opts.cmd then
    M.notify.error("No command provided to reload config")
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
  local cmd
  if opts.restart then
    cmd = string.format("pkill -x '%s' || true; nohup %s > /dev/null 2>&1 & disown", opts.cmd, opts.cmd)
  else
    cmd = string.format("nohup %s > /dev/null 2>&1 & disown", opts.cmd)
  end

  M.set_keymap({
    "<leader>rr",
    function()
      local output = vim.fn.system(cmd)
      local notify_opts = { title = opts.title }
      local error = vim.v.shell_error ~= 0
      local mgs = ("%s %s %s"):format(
        error and "Error reloading" or "Reloaded",
        opts.title,
        error and ": " .. output or ""
      )
      Utils.notify[error and "error" or "info"](mgs, notify_opts)
    end,
    desc = "Reload Config",
    silent = true,
    buffer = opts.buffer,
    icon = { icon = "󰑓 ", color = "orange" },
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

    api.nvim_create_autocmd("User", {
      pattern = "KeymapSet",
      callback = function(event)
        if event.data.has_icon then
          M._apply_which_key()
        end
      end,
    })
  end)
end

return M
