---@class utils.smart_nav
local M = {}
--[[
This module provides intelligent window navigation that remembers your navigation history.
When you navigate between windows using Ctrl+w + h/j/k/l, it tracks where you came from.
If you navigate back in the opposite direction, it will return you to the exact window
you came from, rather than just the nearest window in that direction.
--]]
local win_history = {}
local reverse_direction = { h = "l", j = "k", k = "j", l = "h" }
local last_movement = { from = nil, to = nil, direction = nil }
local last_win = nil

local config = {
  ignore_floating = true,
  keymaps = {
    ["<C-w>h"] = "h",
    ["<C-w>j"] = "j",
    ["<C-w>k"] = "k",
    ["<C-w>l"] = "l",
  },
}

-- Get current window ID
local function get_current_win()
  return vim.api.nvim_get_current_win()
end

-- Check if window still exists
local function win_exists(win_id)
  return vim.api.nvim_win_is_valid(win_id)
end

local function is_floating(win_id)
  if not win_exists(win_id) then return false end
  local win_config = vim.api.nvim_win_get_config(win_id)
  return win_config.relative ~= ""
end

-- Check if target window is actually adjacent in the given direction
local function is_adjacent_window(from_win, to_win, direction)
  if not (win_exists(from_win) and win_exists(to_win)) then return false end

  -- Get window positions
  local from_pos = vim.api.nvim_win_get_position(from_win)
  local to_pos = vim.api.nvim_win_get_position(to_win)
  local from_width = vim.api.nvim_win_get_width(from_win)
  local from_height = vim.api.nvim_win_get_height(from_win)
  local to_width = vim.api.nvim_win_get_width(to_win)
  local to_height = vim.api.nvim_win_get_height(to_win)

  local from_row, from_col = from_pos[1], from_pos[2]
  local to_row, to_col = to_pos[1], to_pos[2]

  local overlapping_vertical = not (to_row + to_height <= from_row or to_row >= from_row + from_height)
  local overlapping_horizontal = not (to_col + to_width <= from_col or to_col >= from_col + from_width)

  if direction == "h" then
    return (to_col + to_width + 1 == from_col) and overlapping_vertical
  elseif direction == "l" then
    return (from_col + from_width + 1 == to_col) and overlapping_vertical
  elseif direction == "k" then
    return (to_row + to_height + 1 == from_row) and overlapping_horizontal
  elseif direction == "j" then
    return (from_row + from_height + 1 == to_row) and overlapping_horizontal
  end

  return false
end

local function cleanup_history()
  for win_id, _ in pairs(win_history) do
    if not win_exists(win_id) then win_history[win_id] = nil end
  end
  for _, directions in pairs(win_history) do
    for dir, prev_win in pairs(directions) do
      if not win_exists(prev_win) then directions[dir] = nil end
    end
  end
end

-- Record the previous window for a direction
local function record_movement(from_win, to_win, direction)
  if config.ignore_floating and (is_floating(from_win) or is_floating(to_win)) then return end

  if not is_adjacent_window(from_win, to_win, direction) then return end

  if not win_history[to_win] then win_history[to_win] = {} end
  local reverse_dir = reverse_direction[direction]
  if reverse_dir then win_history[to_win][reverse_dir] = from_win end
end

function M.smart_navigate(direction)
  local current_win = get_current_win()

  if
    last_movement.from
    and last_movement.to == current_win
    and last_movement.direction == reverse_direction[direction]
  then
    local prev_win = last_movement.from
    if win_exists(prev_win) and is_adjacent_window(current_win, prev_win, direction) then
      vim.api.nvim_set_current_win(prev_win)
      last_movement = { from = current_win, to = prev_win, direction = direction }
      return
    end
  end

  local history = win_history[current_win]
  if history and history[direction] then
    local prev_win = history[direction]
    if win_exists(prev_win) and is_adjacent_window(current_win, prev_win, direction) then
      vim.api.nvim_set_current_win(prev_win)
      last_movement = { from = current_win, to = prev_win, direction = direction }
      return
    else
      history[direction] = nil
    end
  end

  local start_win = current_win
  vim.cmd("wincmd " .. direction)
  local end_win = get_current_win()

  if start_win ~= end_win then
    record_movement(start_win, end_win, direction)
    last_movement = { from = start_win, to = end_win, direction = direction }
  end
end

function M.setup()
  for keymap, direction in pairs(config.keymaps) do
    vim.keymap.set("n", keymap, function()
      M.smart_navigate(direction)
    end, { noremap = true, silent = true, desc = "Smart window navigation" })
  end

  Utils.autocmd.autocmd_augroup("smart_win_nav", {
    {
      events = { "WinLeave" },
      callback = function()
        last_win = get_current_win()
      end,
    },
    {
      events = { "WinEnter" },
      callback = function()
        local current_win = get_current_win()
        if not win_history[current_win] then win_history[current_win] = { h = nil, j = nil, k = nil, l = nil } end

        if last_win and last_win ~= current_win and win_exists(last_win) then
          local from_pos = vim.api.nvim_win_get_position(last_win)
          local to_pos = vim.api.nvim_win_get_position(current_win)
          local from_row, from_col = from_pos[1], from_pos[2]
          local to_row, to_col = to_pos[1], to_pos[2]
          local direction = nil

          if from_row == to_row then
            if to_col > from_col then
              direction = "l"
            elseif to_col < from_col then
              direction = "h"
            end
          elseif from_col == to_col then
            if to_row > from_row then
              direction = "j"
            elseif to_row < from_row then
              direction = "k"
            end
          end

          if
            direction
            and not (config.ignore_floating and (is_floating(last_win) or is_floating(current_win)))
            and is_adjacent_window(last_win, current_win, direction)
          then
            record_movement(last_win, current_win, direction)
            last_movement = { from = last_win, to = current_win, direction = direction }
          end
        end
      end,
    },
    {
      events = { "WinClosed" },
      callback = function()
        vim.schedule(cleanup_history)
      end,
    },
  })
end

function M.get_history()
  return win_history
end

function M.clear_history()
  win_history = {}
  last_movement = { from = nil, to = nil, direction = nil }
end

return M
