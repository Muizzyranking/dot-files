---@class utils.action_manager.ui
local M = {}
local notify = Utils.notify.create({ title = "Action Manager" })
local api = vim.api
local registry = require("utils.action_manager.registry")

local ui_state = {
  buf = nil,
  win = nil,
  selected = 1,
  is_open = false,
  mode = nil, -- "selector" or "group"
  current_group = nil,
  source_buf = nil,
}

local ns = api.nvim_create_namespace("action_manager_ui")

---------------------------------------------------------------
-- Check if UI is open
---------------------------------------------------------------
function M.is_open()
  return ui_state.is_open
end

---------------------------------------------------------------
-- Setup highlights
---------------------------------------------------------------
local function setup_highlights()
  Utils.hl.add_highlights({
    ActionManagerTitle = { fg = "#89b4fa", bold = true },
    ActionManagerBorder = { fg = "#89b4fa" },
    ActionManagerSelected = { bg = "#313244" },
    ActionManagerEnabled = { fg = "#a6e3a1" },
    ActionManagerDisabled = { fg = "#f38ba8" },
    ActionManagerFooter = { fg = "#6c7086", italic = true },
    ActionManagerGroupIcon = { fg = "#cba6f7" },
  })
end

---------------------------------------------------------------
-- Grid utilities
---------------------------------------------------------------
local function get_grid_pos(index, cols)
  local row = math.floor((index - 1) / cols)
  local col = (index - 1) % cols
  return row, col
end

local function get_index(row, col, cols)
  return row * cols + col + 1
end

---------------------------------------------------------------
-- Generate lines for group selector
---------------------------------------------------------------
local function generate_selector_lines()
  local groups = registry.get_groups()
  local lines = {}
  local highlights = {}
  local group_list = {}

  for name, data in pairs(groups) do
    table.insert(group_list, {
      name = name,
      config = data.config,
      count = #data.items,
    })
  end

  table.sort(group_list, function(a, b)
    return a.name < b.name
  end)

  table.insert(lines, "")
  table.insert(highlights, {})

  local line_num = 1
  for i, group in ipairs(group_list) do
    local is_selected = i == ui_state.selected
    local prefix = is_selected and " ▶ " or "   "
    local icon = group.config.icon or "●"
    local title = group.config.title or group.name
    local count_text = string.format("(%d items)", group.count)

    local line = string.format("%s%s %s  %s", prefix, icon, title, count_text)
    table.insert(lines, line)

    local col_start = 0
    local icon_col = vim.fn.strwidth(prefix)
    local icon_len = vim.fn.strwidth(icon)

    table.insert(highlights, {
      line = line_num,
      col_start = col_start,
      col_end = #line,
      icon_col = icon_col,
      icon_len = icon_len,
      is_selected = is_selected,
    })

    line_num = line_num + 1
  end

  return lines, highlights, group_list
end

---------------------------------------------------------------
-- Generate lines for group items (grid layout)
---------------------------------------------------------------
local function generate_group_lines(group_name)
  local items = registry.get_group_items(group_name)
  local config = registry.get_group_config(group_name)
  local cols = config.columns or 2

  local buf = Utils.ensure_buf(ui_state.source_buf)
  for _, item in ipairs(items) do
    if item.type == "toggle" and item.toggle then
      item.toggle:refresh(buf)
      item.state = item.toggle.state
      local icon_data = item.toggle:icon(buf)()
      item.icon = icon_data
      item.name = item.toggle.mapping.name or item.toggle:desc(buf)()
    end
  end

  local lines = {}
  local highlights = {}
  local rows = math.ceil(#items / cols)

  -- Calculate max width
  local max_name_len = 0
  for _, item in ipairs(items) do
    local icon = item.icon and (type(item.icon) == "table" and item.icon.icon or item.icon) or "●"
    local name = item.name or "Unknown"
    local text_len = vim.fn.strwidth(icon .. " " .. name)
    max_name_len = math.max(max_name_len, text_len)
  end

  local col_width = math.max(20, max_name_len + 6)

  -- Empty line for spacing
  table.insert(lines, "")
  table.insert(highlights, {})

  local line_num = 1

  for row = 0, rows - 1 do
    if row > 0 then
      table.insert(lines, "")
      table.insert(highlights, {})
      line_num = line_num + 1
    end

    local line_parts = {}
    local line_highlights = {}

    for col = 0, cols - 1 do
      local index = get_index(row, col, cols)
      local item = items[index]

      if item then
        local is_selected = index == ui_state.selected
        local prefix = is_selected and " ▶ " or "   "

        -- Get icon
        local icon = "●"
        if item.icon then
          if type(item.icon) == "table" then
            icon = item.icon.icon or "●"
          else
            icon = item.icon
          end
        end

        local name = item.name or "Unknown"
        local col_start = #table.concat(line_parts, "")
        local icon_col = col_start + vim.fn.strwidth(prefix)

        local text = string.format("%s%s %s", prefix, icon, name)
        text = text .. string.rep(" ", math.max(0, col_width - vim.fn.strwidth(text)))

        table.insert(line_parts, text)

        -- Determine highlight based on item type
        local state_hl = nil
        if item.type == "toggle" and item.state ~= nil then
          state_hl = item.state and "ActionManagerEnabled" or "ActionManagerDisabled"
        end

        table.insert(line_highlights, {
          line = line_num,
          col_start = col_start,
          col_end = col_start + vim.fn.strwidth(text),
          -- col_end = #text,
          icon_col = icon_col,
          icon_len = vim.fn.strwidth(icon),
          is_selected = is_selected,
          state_hl = state_hl,
        })
      else
        table.insert(line_parts, string.rep(" ", col_width))
      end
    end

    table.insert(lines, table.concat(line_parts, ""))

    for _, hl_info in ipairs(line_highlights) do
      table.insert(highlights, hl_info)
    end

    line_num = line_num + 1
  end

  return lines, highlights, col_width * cols, line_num
end

---------------------------------------------------------------
-- Apply highlights to buffer
---------------------------------------------------------------
local function apply_highlights(buf, highlights)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for _, hl in ipairs(highlights) do
    if hl.is_selected then
      api.nvim_buf_set_extmark(buf, ns, hl.line, hl.col_start, {
        end_col = hl.col_end,
        hl_group = "ActionManagerSelected",
        priority = 100,
      })
    end

    if hl.icon_col and hl.icon_len then
      local icon_hl = hl.state_hl or "ActionManagerGroupIcon"
      api.nvim_buf_set_extmark(buf, ns, hl.line, hl.icon_col, {
        end_col = hl.icon_col + hl.icon_len,
        hl_group = icon_hl,
        priority = 200,
      })
    end
  end
end

---------------------------------------------------------------
-- Redraw current UI
---------------------------------------------------------------
local function redraw()
  if not ui_state.buf or not api.nvim_buf_is_valid(ui_state.buf) then return end

  local lines, highlights

  if ui_state.mode == "selector" then
    lines, highlights = generate_selector_lines()
  elseif ui_state.mode == "group" and ui_state.current_group then
    lines, highlights = generate_group_lines(ui_state.current_group)
  else
    return
  end

  api.nvim_set_option_value("modifiable", true, { buf = ui_state.buf })
  api.nvim_buf_set_lines(ui_state.buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = ui_state.buf })

  apply_highlights(ui_state.buf, highlights)
end

---------------------------------------------------------------
-- Navigation
---@param direction string "h", "j", "k", or "l"
---------------------------------------------------------------
local function move(direction)
  local item_count
  local cols = 1

  if ui_state.mode == "selector" then
    item_count = registry.get_group_count()
  elseif ui_state.mode == "group" and ui_state.current_group then
    item_count = registry.get_item_count(ui_state.current_group)
    local config = registry.get_group_config(ui_state.current_group)
    cols = config.columns or 2
  else
    return
  end

  if item_count == 0 then return end

  local rows = math.ceil(item_count / cols)
  local row, col = get_grid_pos(ui_state.selected, cols)

  if direction == "h" then
    col = math.max(0, col - 1)
  elseif direction == "l" then
    col = math.min(cols - 1, col + 1)
  elseif direction == "k" then
    row = math.max(0, row - 1)
  elseif direction == "j" then
    row = math.min(rows - 1, row + 1)
  end

  local new_index = get_index(row, col, cols)
  if new_index >= 1 and new_index <= item_count then
    ui_state.selected = new_index
    redraw()
  end
end

---------------------------------------------------------------
-- Execute selected item
---------------------------------------------------------------
local function execute_selected()
  if ui_state.mode == "selector" then
    -- Get selected group
    local groups = registry.get_groups()
    local group_list = {}
    for name in pairs(groups) do
      table.insert(group_list, name)
    end
    table.sort(group_list)

    local selected_group = group_list[ui_state.selected]
    if selected_group then
      M.close_ui()
      M.show_group_ui(selected_group)
    end
  elseif ui_state.mode == "group" and ui_state.current_group then
    local items = registry.get_group_items(ui_state.current_group)
    local item = items[ui_state.selected]

    if item then
      if item.type == "toggle" and item.toggle then
        item.toggle:toggle(ui_state.source_buf)
        redraw()
      elseif item.execute then
        item.execute(ui_state.source_buf)
      end
    end
  end
end

---------------------------------------------------------------
-- Go back (only in group mode)
---------------------------------------------------------------
local function go_back()
  if ui_state.mode == "group" then
    M.close_ui()
    M.show_selector_ui()
  end
end

---------------------------------------------------------------
-- Close UI
---------------------------------------------------------------
function M.close_ui()
  ui_state.is_open = false

  if ui_state.win and api.nvim_win_is_valid(ui_state.win) then pcall(api.nvim_win_close, ui_state.win, true) end

  if ui_state.buf and api.nvim_buf_is_valid(ui_state.buf) then
    vim.schedule(function()
      if api.nvim_buf_is_valid(ui_state.buf) then pcall(api.nvim_buf_delete, ui_state.buf, { force = true }) end
    end)
  end

  ui_state.buf = nil
  ui_state.win = nil
  ui_state.selected = 1
  ui_state.mode = nil
  ui_state.current_group = nil
  ui_state.source_buf = nil
end

---------------------------------------------------------------
-- Setup keymaps
---------------------------------------------------------------
local function setup_keymaps(buf, mode)
  local opts = { buffer = buf, nowait = true, silent = true }
  local map = function(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, opts)
  end
  local move_map = function(direction)
    local lhs = direction
    local rhs = function()
      move(direction)
    end
    map(lhs, rhs)
  end

  for _, key in ipairs({ "h", "j", "k", "l" }) do
    move_map(key)
  end

  map("<CR>", execute_selected)
  map("<space>", execute_selected)

  if mode == "group" then
    map("<BS>", go_back)
    map("b", go_back)
  end

  map("<esc>", M.close_ui)
  map("q", M.close_ui)
end

---------------------------------------------------------------
-- Create window
---------------------------------------------------------------
local function create_window(title, width, height, footer)
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines

  local col = math.floor((editor_width - width) / 2)
  local row = math.floor((editor_height - height) / 2)

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    footer = footer or "hjkl: navigate • Enter: select • q: quit",
    footer_pos = "center",
  }

  local win = api.nvim_open_win(ui_state.buf, true, win_opts)

  vim.wo[win].cursorline = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = false
  vim.wo[win].scrolloff = 3

  return win
end

---------------------------------------------------------------
-- Show group selector UI
---------------------------------------------------------------
function M.show_selector_ui(opts)
  if ui_state.is_open then
    M.close_ui()
    return
  end

  opts = opts or {}
  ui_state.source_buf = api.nvim_get_current_buf()
  ui_state.mode = "selector"
  ui_state.selected = 1

  local group_count = registry.get_group_count()
  if group_count == 0 then
    notify.warn("No action groups registered")
    return
  end

  setup_highlights()

  local buf = api.nvim_create_buf(false, true)
  ui_state.buf = buf

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false

  local width = math.min(60, vim.o.columns - 10)
  local height = math.min(group_count + 5, vim.o.lines - 10)

  ui_state.win = create_window("Action Groups", width, height)
  ui_state.is_open = true

  api.nvim_set_option_value("modifiable", false, { buf = buf })

  setup_keymaps(buf, "selector")

  redraw()

  api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      if ui_state.is_open then vim.schedule(function()
        M.close_ui()
      end) end
    end,
  })
end

function M.show_group_ui(group_name, opts)
  if ui_state.is_open then M.close_ui() end

  opts = opts or {}
  ui_state.source_buf = api.nvim_get_current_buf()
  ui_state.mode = "group"
  ui_state.current_group = group_name
  ui_state.selected = 1

  local items = registry.get_group_items(group_name)
  if #items == 0 then
    notify.warn(string.format("No items in group '%s'", group_name))
    return
  end

  local config = registry.get_group_config(group_name)

  for _, item in ipairs(items) do
    if item.type == "toggle" and item.toggle then
      item.toggle:refresh(ui_state.source_buf)
      item.state = item.toggle.state
    end
  end

  setup_highlights()

  local buf = api.nvim_create_buf(false, true)
  ui_state.buf = buf

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false

  local _, _, calculated_width, content_lines = generate_group_lines(group_name)
  local width = math.min(math.max(50, calculated_width + 4), vim.o.columns - 10)
  local height = math.min(content_lines + 3, vim.o.lines - 10)

  local footer = config.footer or "hjkl: navigate • Enter: execute • b: back • q: quit"
  ui_state.win = create_window(config.title or group_name, width, height, footer)
  ui_state.is_open = true

  api.nvim_set_option_value("modifiable", false, { buf = buf })

  setup_keymaps(buf, "group")

  redraw()

  api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      if ui_state.is_open then vim.schedule(function()
        M.close_ui()
      end) end
    end,
  })
end

return M
