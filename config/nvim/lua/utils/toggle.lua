---@class utils.toggle
local M = setmetatable({}, {
  __call = function(m, mapping)
    return m.create(mapping)
  end,
})

local notify = Utils.notify.create({ title = "Toggle Manager" })
local api = vim.api
local ns = api.nvim_create_namespace("toggle_manager_ui")

local toggles = {}
local ui_state = {
  buf = nil,
  win = nil,
  selected = 1,
  is_open = false,
  source_buf = nil,
}
local config = {
  columns = 3,
  title = "Toggles",
  icon = "⚙",
  footer = "hjkl: navigate • Enter: toggle • q: quit",
}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

---@class Toggle
---@field mapping toggle.Opts
---@field buf number
---@field state boolean
local Toggle = {}
Toggle.__index = Toggle

---@param mapping toggle.Opts
---@return Toggle
function Toggle:new(mapping)
  self = setmetatable({}, Toggle)
  self.mapping = mapping
  self:refresh()
  return self
end

function Toggle:is_valid()
  local mapping = self.mapping
  return type(mapping) == "table"
    and type(mapping[1]) == "string"
    and vim.is_callable(mapping.get_state)
    and vim.is_callable(mapping.change_state)
    and (mapping.notify == false or type(mapping.name) == "string")
end

---Refresh current buffer and state
---@param buf? number
function Toggle:refresh(buf)
  self.buf = buf or Utils.ensure_buf(self.mapping.buffer or 0)
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
---@param buf? number
function Toggle:toggle(buf)
  self:refresh(buf)
  self.mapping.change_state(self.state, self.buf)
  self:notify()
end

---Get description for the mapping
---@return string|function
function Toggle:desc(buf)
  return function()
    self:refresh(buf)
    if Utils.type(self.mapping.desc, "function") then return self.mapping.desc(self.state) end
    return self.mapping.desc or string.format("Toggle %s", self.mapping.name)
  end
end

---Get icon
---@return fun(): table
function Toggle:icon(buf)
  return function()
    self:refresh(buf)
    local icon = self.mapping.icon or {}
    local color = self.mapping.color or {}
    local state = self.state
    return {
      icon = state and (icon.enabled or "  ") or (icon.disabled or "  "),
      color = state and (color.enabled or "green") or (color.disabled or "yellow"),
    }
  end
end

function Toggle:to_keymap()
  local map = {
    self.mapping[1],
    function()
      self:toggle()
    end,
    mode = self.mapping.mode or "n",
    desc = self:desc(),
    icon = self:icon(),
  }
  local excluded = { "name", "get_state", "toggle_fn", "change_state", "color", "notify", "set_key", "ui" }
  for k, v in pairs(self.mapping) do
    if map[k] == nil and not vim.tbl_contains(excluded, k) then map[k] = v end
  end
  return map
end

function Toggle:register_to_ui()
  if self.mapping.ui == false then return end
  M.register(self.mapping)
end

---------------------------------------------------------------
---Create a toggle mapping
---@param mapping toggle.Opts
---@return map.KeymapOpts?
---------------------------------------------------------------
function M.create(mapping)
  local toggle = Toggle:new(mapping)
  if not toggle:is_valid() then return nil end
  toggle:register_to_ui()
  local key = toggle:to_keymap()
  if mapping.set_key ~= false then Utils.map.set_keymap(key) end
  return key
end

---------------------------------------------------------------
---Create multiple toggle mappings
---@param mappings toggle.Opts[]
---@return map.KeymapOpts[]? # Returns array of mappings if set_key=false, nil otherwise
---------------------------------------------------------------
function M.group(mappings, opts)
  if type(mappings) ~= "table" then return nil end
  local results = {}
  opts = opts or {}
  for _, map in ipairs(mappings) do
    local merged_opts = vim.tbl_deep_extend("force", {}, opts, map)
    local result = M.create(merged_opts)
    if result then table.insert(results, result) end
  end
  return #results > 0 and results or nil
end

---@param toggle Toggle Toggle instance
function M.register(toggle)
  for i, existing in ipairs(toggles) do
    if existing == toggle then
      toggles[i] = toggle
      return
    end
  end

  table.insert(toggles, toggle)
end

local function setup_highlights()
  Utils.hl.add_highlights({
    ToggleManagerTitle = { fg = "#89b4fa", bold = true },
    ToggleManagerBorder = { fg = "#89b4fa" },
    ToggleManagerSelected = { bg = "#313244" },
    ToggleManagerEnabled = { fg = "#a6e3a1" },
    ToggleManagerDisabled = { fg = "#f38ba8" },
    ToggleManagerFooter = { fg = "#6c7086", italic = true },
  })
end

local function get_grid_pos(index, cols)
  local row = math.floor((index - 1) / cols)
  local col = (index - 1) % cols
  return row, col
end

local function get_index(row, col, cols)
  return row * cols + col + 1
end

local function generate_lines()
  local cols = config.columns
  local buf = Utils.ensure_buf(ui_state.source_buf)

  for _, toggle in ipairs(toggles) do
    toggle:refresh(buf)
  end

  local lines = {}
  local highlights = {}
  local rows = math.ceil(#toggles / cols)

  local max_name_len = 0
  for _, toggle in ipairs(toggles) do
    local icon_data = toggle:icon(buf)()
    local icon = type(icon_data) == "table" and icon_data.icon or icon_data or "●"
    local name = toggle.mapping.name or toggle:desc(buf)()
    local text_len = vim.fn.strwidth(icon .. " " .. name)
    max_name_len = math.max(max_name_len, text_len)
  end

  local col_width = math.max(20, max_name_len + 6)

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
      local toggle = toggles[index]

      if toggle then
        local is_selected = index == ui_state.selected
        local prefix = is_selected and " ▶ " or "   "

        -- Get icon
        local icon_data = toggle:icon(buf)()
        local icon = type(icon_data) == "table" and icon_data.icon or icon_data or "●"

        local name = toggle.mapping.name or toggle:desc(buf)()
        local col_start = #table.concat(line_parts, "")
        local icon_col = col_start + vim.fn.strwidth(prefix)

        local text = string.format("%s%s %s", prefix, icon, name)
        text = text .. string.rep(" ", math.max(0, col_width - vim.fn.strwidth(text)))

        table.insert(line_parts, text)

        local state_hl = toggle.state and "ToggleManagerEnabled" or "ToggleManagerDisabled"

        table.insert(line_highlights, {
          line = line_num,
          col_start = col_start,
          col_end = col_start + vim.fn.strwidth(text),
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

local function apply_highlights(buf, highlights)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for _, hl in ipairs(highlights) do
    if hl.is_selected then
      api.nvim_buf_set_extmark(buf, ns, hl.line, hl.col_start, {
        end_col = hl.col_end,
        hl_group = "ToggleManagerSelected",
        priority = 100,
      })
    end

    if hl.icon_col and hl.icon_len then
      api.nvim_buf_set_extmark(buf, ns, hl.line, hl.icon_col, {
        end_col = hl.icon_col + hl.icon_len,
        hl_group = hl.state_hl,
        priority = 200,
      })
    end
  end
end

local function redraw()
  if not ui_state.buf or not api.nvim_buf_is_valid(ui_state.buf) then return end

  local lines, highlights = generate_lines()

  api.nvim_set_option_value("modifiable", true, { buf = ui_state.buf })
  api.nvim_buf_set_lines(ui_state.buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = ui_state.buf })

  apply_highlights(ui_state.buf, highlights)
end

---------------------------------------------------------------
-- Navigation
---------------------------------------------------------------
local function move(direction)
  local cols = config.columns
  local item_count = #toggles

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

local function execute_selected()
  local toggle = toggles[ui_state.selected]
  if toggle then
    toggle:toggle(ui_state.source_buf)
    redraw()
  end
end

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
  ui_state.source_buf = nil
end

function M.is_open()
  return ui_state.is_open
end

local function setup_keymaps(buf)
  local opts = { buffer = buf, nowait = true, silent = true }
  local map = function(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, opts)
  end

  for _, key in ipairs({ "h", "j", "k", "l" }) do
    map(key, function()
      move(key)
    end)
  end

  map("<CR>", execute_selected)
  map("<space>", execute_selected)
  map("<esc>", M.close_ui)
  map("q", M.close_ui)
end

local function create_window(width, height)
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
    title = " " .. config.title .. " ",
    title_pos = "center",
    footer = config.footer,
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

function M.show_ui(opts)
  if ui_state.is_open then
    M.close_ui()
    return
  end

  opts = opts or {}
  ui_state.source_buf = api.nvim_get_current_buf()
  ui_state.selected = 1

  if #toggles == 0 then
    notify.warn("No toggles registered")
    return
  end

  setup_highlights()

  local buf = api.nvim_create_buf(false, true)
  ui_state.buf = buf

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false

  local _, _, calculated_width, content_lines = generate_lines()
  local width = math.min(math.max(50, calculated_width + 4), vim.o.columns - 10)
  local height = math.min(content_lines + 3, vim.o.lines - 10)

  ui_state.win = create_window(width, height)
  ui_state.is_open = true

  api.nvim_set_option_value("modifiable", false, { buf = buf })

  setup_keymaps(buf)

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

function M.toggle_ui(opts)
  if M.is_open() then
    M.close_ui()
  else
    M.show_ui(opts)
  end
end

return M
