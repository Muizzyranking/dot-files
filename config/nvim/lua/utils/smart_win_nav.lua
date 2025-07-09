---@class utils.smart_win_nav
--[[
This module provides intelligent window navigation that remembers your navigation history.
When you navigate between windows using Ctrl+w + h/j/k/l, it tracks where you came from.
If you navigate back in the opposite direction, it will return you to the exact window
you came from, rather than just the nearest window in that direction.
--]]
local M = {}

M.config = {
  allowed_filetypes = { "help", "man", "qf" },
}

local OPPOSITES = { h = "l", j = "k", k = "j", l = "h" }

-- State tracking
local state = {
  current_win = nil,
  last_direction = nil,
  navigation_in_progress = false,
}

-----------------------------------------------------------------------------
---Get window-local history variable name for a direction
---@param direction string
---@return string
-----------------------------------------------------------------------------
local function get_history_var(direction)
  return "smart_nav_from_" .. direction
end

-----------------------------------------------------------------------------
---Check if a window exists and is valid
---@param winid number
---@return boolean
-----------------------------------------------------------------------------
local function is_valid_window(winid)
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return false
  end

  local config = vim.api.nvim_win_get_config(winid)
  if config.relative ~= "" then
    return false
  end

  return true
end

-----------------------------------------------------------------------------
---Check if buffer is allowed for navigation
---@param bufnr number
---@return boolean
-----------------------------------------------------------------------------
local function is_buffer_allowed(bufnr)
  bufnr = Utils.ensure_buf(bufnr)

  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  if vim.tbl_contains(M.config.allowed_filetypes, filetype) then
    return true
  end
  return not Utils.ignore_buftype(bufnr) and not Utils.ignore_filetype(bufnr)
end

-----------------------------------------------------------------------------
---Check if window is valid for navigation
---@param winid number
---@return boolean
-----------------------------------------------------------------------------
local function is_valid_nav_win(winid)
  if not is_valid_window(winid) then
    return false
  end

  local bufnr = vim.api.nvim_win_get_buf(winid)
  return is_buffer_allowed(bufnr)
end

-----------------------------------------------------------------------------
---Calculate distance between windows in a specific direction
---@param from_pos table
---@param from_size table
---@param to_pos table
---@param to_size table
---@param direction string
---@return number distance, boolean is_target
-----------------------------------------------------------------------------
local function calculate_win_distance(from_pos, from_size, to_pos, to_size, direction)
  local is_target, distance
  if direction == "h" then -- left
    is_target = to_pos[2] + to_size.width <= from_pos[2]
    distance = from_pos[2] - (to_pos[2] + to_size.width) + math.abs(to_pos[1] - from_pos[1])
  elseif direction == "l" then -- right
    is_target = to_pos[2] >= from_pos[2] + from_size.width
    distance = to_pos[2] - (from_pos[2] + from_size.width) + math.abs(to_pos[1] - from_pos[1])
  elseif direction == "k" then -- up
    is_target = to_pos[1] + to_size.height <= from_pos[1]
    distance = from_pos[1] - (to_pos[1] + to_size.height) + math.abs(to_pos[2] - from_pos[2])
  elseif direction == "j" then -- down
    is_target = to_pos[1] >= from_pos[1] + from_size.height
    distance = to_pos[1] - (from_pos[1] + from_size.height) + math.abs(to_pos[2] - from_pos[2])
  end
  return distance, is_target
end

-----------------------------------------------------------------------------
---Get the window ID in a specific direction from current window
---@param direction string
---@return number?
-----------------------------------------------------------------------------
local function get_window_in_direction(direction)
  local current = vim.api.nvim_get_current_win()
  local current_pos = vim.api.nvim_win_get_position(current)
  local current_size = {
    width = vim.api.nvim_win_get_width(current),
    height = vim.api.nvim_win_get_height(current),
  }

  local best_win, best_distance = nil, math.huge
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if winid ~= current then
      local pos = vim.api.nvim_win_get_position(winid)
      local size = {
        width = vim.api.nvim_win_get_width(winid),
        height = vim.api.nvim_win_get_height(winid),
      }

      local distance, is_target = calculate_win_distance(current_pos, current_size, pos, size, direction)

      if is_target and distance < best_distance then
        best_distance = distance
        best_win = winid
      end
    end
  end

  return best_win
end

-----------------------------------------------------------------------------
---Clean up invalid window references from history
-----------------------------------------------------------------------------
local function cleanup_invalid_windows()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    for direction in pairs(OPPOSITES) do
      local var_name = get_history_var(direction)
      local ok, stored_win = pcall(vim.api.nvim_win_get_var, winid, var_name)
      if ok and stored_win and not is_valid_nav_win(stored_win) then
        pcall(vim.api.nvim_win_del_var, winid, var_name)
      end
    end
  end
end

-----------------------------------------------------------------------------
---Store navigation history
---@param from_win number
---@param to_win number
---@param direction string
-----------------------------------------------------------------------------
local function store_navigation_history(from_win, to_win, direction)
  if not is_valid_nav_win(from_win) or not is_valid_nav_win(to_win) then
    return
  end

  -- local opposite_dir = DIRECTIONS[direction].opposite
  local opposite_dir = OPPOSITES[direction]
  local var_name = get_history_var(opposite_dir)
  pcall(vim.api.nvim_win_set_var, to_win, var_name, from_win)
end

-----------------------------------------------------------------------------
---Get stored navigation history
---@param direction string
---@return number?
-----------------------------------------------------------------------------
local function get_navigation_history(direction)
  local current = vim.api.nvim_get_current_win()
  local var_name = get_history_var(direction)

  local ok, stored_win = pcall(vim.api.nvim_win_get_var, current, var_name)
  if ok and stored_win and is_valid_nav_win(stored_win) then
    return stored_win
  end

  return nil
end

---@param history_win number
---@param direction string
---@param start_win number
---@return boolean
local function is_history_valid(history_win, direction, start_win)
  local opposite_dir = OPPOSITES[direction]

  -- Temporarily switch to history window to check reverse direction
  local original_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(history_win)
  local reverse_target = get_window_in_direction(opposite_dir)
  vim.api.nvim_set_current_win(original_win)

  return reverse_target == start_win
end

-----------------------------------------------------------------------------
---Perform smart window navigation
---@param direction string
-----------------------------------------------------------------------------
function M.smart_navigate(direction)
  if state.navigation_in_progress then
    return
  end

  state.navigation_in_progress = true
  local start_win = vim.api.nvim_get_current_win()

  local history_win = get_navigation_history(direction)
  local normal_target = get_window_in_direction(direction)

  local target_win = nil

  if history_win and normal_target and is_history_valid(history_win, direction, start_win) then
    target_win = history_win
  else
    if history_win then
      local var_name = get_history_var(direction)
      pcall(vim.api.nvim_win_del_var, start_win, var_name)
    end
    target_win = normal_target
  end

  if target_win then
    vim.api.nvim_set_current_win(target_win)
    store_navigation_history(start_win, target_win, direction)
    state.last_direction = direction
    state.current_win = target_win
  else
    vim.cmd("wincmd " .. direction)
  end

  state.navigation_in_progress = false
end

---@param old_win number
---@param new_win number
local function clear_relevant_history(old_win, new_win)
  -- Don't try to clear history if old window is invalid
  if not is_valid_nav_win(old_win) then
    -- Just clear all history for the new window
    for direction in pairs(OPPOSITES) do
      local var_name = get_history_var(direction)
      pcall(vim.api.nvim_win_del_var, new_win, var_name)
    end
    return
  end

  local cleared_any = false

  for direction in pairs(OPPOSITES) do
    -- Check if new window is in this direction from old window
    local temp_current = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(old_win)
    local target_in_direction = get_window_in_direction(direction)
    vim.api.nvim_set_current_win(temp_current)

    if target_in_direction == new_win then
      local opposite_dir = OPPOSITES[direction]
      local var_name = get_history_var(opposite_dir)
      pcall(vim.api.nvim_win_del_var, new_win, var_name)
      cleared_any = true
    end
  end

  -- If no specific direction was cleared, clear all history
  if not cleared_any then
    for direction in pairs(OPPOSITES) do
      local var_name = get_history_var(direction)
      pcall(vim.api.nvim_win_del_var, new_win, var_name)
    end
  end
end

-----------------------------------------------------------------------------
---Handle window enter events
-----------------------------------------------------------------------------
local function on_win_enter()
  if state.navigation_in_progress then
    return
  end

  local new_win = vim.api.nvim_get_current_win()
  if state.current_win and state.current_win ~= new_win and not state.last_direction then
    clear_relevant_history(state.current_win, new_win)
  end

  state.current_win = new_win
  state.last_direction = nil
  cleanup_invalid_windows()
end

-----------------------------------------------------------------------------
-- Handle window leave events
-----------------------------------------------------------------------------
local function on_win_leave()
  state.current_win = vim.api.nvim_get_current_win()
end

------------------------------------
-- setup function
------------------------------------
local function setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  Utils.autocmd.autocmd_augroup("smart_window_navigation", {
    {
      events = { "WinEnter" },
      callback = function()
        on_win_enter()
      end,
    },
    {
      events = { "WinLeave" },
      callback = function()
        on_win_leave()
      end,
    },
    {
      events = { "VimLeavePre" },
      callback = function()
        cleanup_invalid_windows()
      end,
    },
  })

  for direction in pairs(OPPOSITES) do
    vim.keymap.set("n", "<C-w>" .. direction, function()
      M.smart_navigate(direction)
    end, {
      desc = "Smart window navigation " .. direction,
      silent = true,
    })
  end
  vim.keymap.set("n", "<C-w>o", function()
    vim.cmd("wincmd o")
    M.clear_history()
  end, {
    desc = "Close other windows and clear navigation history",
    silent = true,
  })

  state.current_win = vim.api.nvim_get_current_win()
end

function M.clear_history()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    for direction in pairs(OPPOSITES) do
      local var_name = get_history_var(direction)
      pcall(vim.api.nvim_win_del_var, winid, var_name)
    end
  end
end

function M.debug_info()
  local info = {}
  local current = vim.api.nvim_get_current_win()

  info.current_window = current
  info.history = {}

  for direction in pairs(OPPOSITES) do
    local var_name = get_history_var(direction)
    local ok, stored_win = pcall(vim.api.nvim_win_get_var, current, var_name)
    if ok and stored_win then
      info.history[direction] = stored_win
    end
  end

  return info
end

function M.setup()
  Utils.autocmd.on_very_lazy(function()
    setup()
  end, { group = "smart_win_navigation" })
end

return M
