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

-- Clean up history for closed windows
local function cleanup_history()
  for win_id, _ in pairs(win_history) do
    if not win_exists(win_id) then win_history[win_id] = nil end
  end

  -- Clean up invalid references in remaining windows
  for _, directions in pairs(win_history) do
    for dir, prev_win in pairs(directions) do
      if not win_exists(prev_win) then directions[dir] = nil end
    end
  end
end

-- Record the previous window for a direction
local function record_movement(from_win, to_win, direction)
  if config.ignore_floating and (is_floating(from_win) or is_floating(to_win)) then return end

  if not win_history[to_win] then win_history[to_win] = {} end

  local reverse_dir = reverse_direction[direction]
  if reverse_dir then win_history[to_win][reverse_dir] = from_win end
end

-- Smart navigation function
local function smart_navigate(direction)
  local current_win = get_current_win()

  local history = win_history[current_win]
  if history and history[direction] then
    local prev_win = history[direction]

    -- If the previous window still exists, go there
    if win_exists(prev_win) then
      record_movement(current_win, prev_win, direction)
      vim.api.nvim_set_current_win(prev_win)
      return
    else
      history[direction] = nil
    end
  end

  local start_win = current_win
  vim.cmd("wincmd " .. direction)
  local end_win = get_current_win()

  if start_win ~= end_win then record_movement(start_win, end_win, direction) end
end

function M.setup()
  Utils.autocmd.on_very_lazy(function()
    for keymap, direction in pairs(config.keymaps) do
      vim.keymap.set("n", keymap, function()
        smart_navigate(direction)
      end, { noremap = true, silent = true, desc = "Smart window navigation" })
    end

    Utils.autocmd.autocmd_augroup("smart_window_navigation", {
      {
        events = { "WinEnter" },
        callback = function()
          local current_win = get_current_win()
          if not win_history[current_win] then win_history[current_win] = { h = nil, j = nil, k = nil, l = nil } end
        end,
      },
      {
        events = { "WinClosed" },
        callback = function()
          vim.schedule(cleanup_history)
        end,
      },
    })
  end, { group = "smart_win_navigation" })
end

function M.get_history()
  return win_history
end

function M.clear_history()
  win_history = {}
end

return M
