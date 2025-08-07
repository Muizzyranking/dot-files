---@class utils.word_cycle
local M = {}

---@type word_cycle.Config
M.config = {
  keymap = "gw",
  global_cycle = {
    { "true", "false" },
    { "on", "off" },
    { "yes", "no" },
    { "left", "right" },
    { "up", "down" },
    { "before", "after" },
    { "first", "last" },
    { "start", "end" },
    { "enable", "disable" },
    { "enabled", "disabled" },
    { "show", "hide" },
    { "open", "close" },
    { "min", "max" },
    { "get", "set" },
    { "add", "remove" },
    { "push", "pop" },
    { "head", "tail" },
    { "top", "bottom" },
    { "next", "prev", "previous" },
    { "public", "private", "protected" },
  },
  filetype_cycle = {},
}
---@type word_cycle.CycleList[]
local global_cycle = nil
---@type word_cycle.FiletypeCycle[]
local filetype_cycle = {}

local notify = Utils.notify.create({ title = "Word Cycle" })

-------------------------------------------------
-- Create lookup tables for faster searching
---@param cycles word_cycle.CycleList[]
---@return word_cycle.CycleLookup
-------------------------------------------------
local function create_lookup_table(cycles)
  local lookup = {}
  for _, cycle_list in ipairs(cycles) do
    for i, word in ipairs(cycle_list) do
      lookup[word] = {
        list = cycle_list,
        current_index = i,
      }
    end
  end
  return lookup
end

-------------------------------------------------
-- Get the next word in the cycle
---@param word string
---@param lookup word_cycle.CycleLookup
-------------------------------------------------
local function get_next_word(word, lookup)
  local entry = lookup[word]
  if not entry then return nil end

  local next_index = entry.current_index + 1
  if next_index > #entry.list then next_index = 1 end

  return entry.list[next_index]
end

-------------------------------------------------
-- Get word under cursor
---@return string?, integer?, integer?
-------------------------------------------------
local function get_word_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  local word_start = col
  local word_end = col

  while word_start > 0 and line:sub(word_start, word_start):match("[%w_]") do
    word_start = word_start - 1
  end
  word_start = word_start + 1

  while word_end < #line and line:sub(word_end + 1, word_end + 1):match("[%w_]") do
    word_end = word_end + 1
  end

  if word_start > word_end then return nil, nil, nil end

  local word = line:sub(word_start, word_end)
  return word, word_start - 1, word_end - 1 -- Convert to 0-based indexing
end

-------------------------------------------------
-- Replace word under cursor
---@param new_word string
---@param start_col integer
---@param end_col integer
-------------------------------------------------
local function replace_word_under_cursor(new_word, start_col, end_col)
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  vim.api.nvim_buf_set_text(0, row, start_col, row, end_col + 1, { new_word })
end

------------------------------------------------
-- Main cycle function
------------------------------------------------
function M.toggle()
  local word, start_col, end_col = get_word_under_cursor()

  if not word or word == "" then
    notify.warn("No word under cursor")
    return
  end

  local filetype = vim.bo.filetype

  local global_lookup = create_lookup_table(global_cycle)
  local filetype_lookup = {}

  if filetype_cycle[filetype] then filetype_lookup = create_lookup_table(filetype_cycle[filetype]) end

  local next_word = get_next_word(word, filetype_lookup) or get_next_word(word, global_lookup)

  if next_word then
    replace_word_under_cursor(next_word, start_col, end_col)
  else
    notify(string.format("No cycle found for: %s", word))
  end
end

-------------------------------------------------
-- Add to global cycles
---@param cycle_list word_cycle.CycleList
-------------------------------------------------
function M.add_global_cycle(cycle_list)
  if type(cycle_list) == "table" or #cycle_list > 2 then table.insert(global_cycle, cycle_list) end
end

-------------------------------------------------
-- Add to filetype cycle
---@param filetype string
---@param cycle_lists word_cycle.CycleList[]
-------------------------------------------------
function M.add_filetype_cycles(filetype, cycle_lists)
  if not filetype_cycle[filetype] then filetype_cycle[filetype] = {} end
  for _, cycle_list in ipairs(cycle_lists) do
    if type(cycle_list) == "table" or #cycle_list > 2 then table.insert(filetype_cycle[filetype], cycle_list) end
  end
end

-------------------------------------------------
-- Get current global cycle (for debugging/inspection)
-------------------------------------------------
function M.get_global_cycle()
  return vim.deepcopy(global_cycle)
end

-------------------------------------------------
-- Get current filetype cycle (for debugging/inspection)
---@param filetype string?
---@return word_cycle.CycleList[]
-------------------------------------------------
function M.get_filetype_cycle(filetype)
  filetype = filetype or vim.bo.filetype
  if filetype_cycle[filetype] then return vim.deepcopy(filetype_cycle[filetype]) end
  return {}
end

-------------------------------------------------
-- Setup function with optional configuration
---@param config word_cycle.Config
-------------------------------------------------
function M.setup(config)
  config = config or {}
  M.config = vim.tbl_deep_extend("force", M.config, config)
  global_cycle = M.config.global_cycle or {}
  filetype_cycle = M.config.filetype_cycle or {}

  if config.keymap ~= false then
    local keymap = config.keymap or "gw"
    vim.keymap.set("n", keymap, M.toggle, { desc = "Cycle word under cursor" })
  end
end

return M
