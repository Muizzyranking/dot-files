---@class utils.lsp.breadcrumb
local M = {}

M.config = {
  separator = " > ",
  max_depth = nil,
  debounce_ms = 100,
  padding = { left = 1, right = 1 },
}

-- Cache
local cache = {
  bufnr = nil,
  row = nil,
  col = nil,
  changedtick = nil,
  symbols = nil,
}

-- Debounce timer
local debounce_timer = nil

-- Request state
local requesting = false

-- LSP symbol kinds to highlight group mapping for icons
local symbol_hl = {
  [1] = "BreadcrumbsFile",
  [2] = "BreadcrumbsModule",
  [3] = "BreadcrumbsNamespace",
  [4] = "BreadcrumbsPackage",
  [5] = "BreadcrumbsClass",
  [6] = "BreadcrumbsMethod",
  [7] = "BreadcrumbsProperty",
  [8] = "BreadcrumbsField",
  [9] = "BreadcrumbsConstructor",
  [10] = "BreadcrumbsEnum",
  [11] = "BreadcrumbsInterface",
  [12] = "BreadcrumbsFunction",
  [13] = "BreadcrumbsVariable",
  [14] = "BreadcrumbsConstant",
  [15] = "BreadcrumbsString",
  [16] = "BreadcrumbsNumber",
  [17] = "BreadcrumbsBoolean",
  [18] = "BreadcrumbsArray",
  [19] = "BreadcrumbsObject",
  [20] = "BreadcrumbsKey",
  [21] = "BreadcrumbsNull",
  [22] = "BreadcrumbsEnumMember",
  [23] = "BreadcrumbsStruct",
  [24] = "BreadcrumbsEvent",
  [25] = "BreadcrumbsOperator",
  [26] = "BreadcrumbsTypeParameter",
}

local function get_icon(kind_name, kind_num)
  local icon = ""
  local hl = symbol_hl[kind_num] or "Normal"

  icon = Utils.icons.kinds[kind_name]
  if icon == nil then
    local has_mini_icons, mini_icons = pcall(require, "mini.icons")
    if has_mini_icons then
      local mini_icon, _ = mini_icons.get("lsp", kind_name)
      icon = mini_icon or ""
    end
  end

  icon = icon:match("^%s*(.-)%s*$")

  return icon, hl
end

--- Checks if a cursor position (line, char) is inside an LSP range.
--- LSP ranges are inclusive at start, exclusive at end.
---@param range any LSP Range object
---@param line number Zero-indexed line number
---@param char number Zero-indexed character number
---@return boolean
local function range_contains_pos(range, line, char)
  local start = range.start
  local stop = range["end"]

  if line < start.line or line > stop.line then return false end
  if line == start.line and char < start.character then return false end
  if line == stop.line and char >= stop.character then return false end
  return true
end

--- Calculate the size of a range for sorting by specificity
---@param range any LSP Range object
---@return number
local function range_size(range)
  local start = range.start
  local stop = range["end"]
  return (stop.line - start.line) * 10000 + (stop.character - start.character)
end

--- Check if cursor is in symbol, prioritizing selectionRange over range
---@param symbol any LSP symbol
---@param row number Zero-indexed line
---@param col number Zero-indexed column
---@return boolean in_range
---@return number priority (2 = in selectionRange, 1 = in range, 0 = not in symbol)
local function check_symbol_position(symbol, row, col)
  -- Prefer selectionRange (just the identifier) over range (entire declaration)
  if symbol.selectionRange and range_contains_pos(symbol.selectionRange, row, col) then return true, 2 end

  local range = symbol.range or (symbol.location and symbol.location.range)
  if range and range_contains_pos(range, row, col) then return true, 1 end

  return false, 0
end

--- Find the deepest/most specific symbol path at cursor position
---@param symbols any[] List of LSP symbols
---@param row number Zero-indexed line
---@param col number Zero-indexed column
---@param path table[] Current path of symbols
---@return table[] Path to deepest symbol
local function find_symbols_at_position(symbols, row, col, path)
  path = path or {}
  local best_path = path
  local best_priority = 0

  -- Filter and sort symbols by specificity (smaller ranges first)
  local candidates = {}
  for _, symbol in ipairs(symbols) do
    local in_range, priority = check_symbol_position(symbol, row, col)
    if in_range then
      table.insert(candidates, {
        symbol = symbol,
        priority = priority,
        size = range_size(symbol.range or symbol.location.range),
      })
    end
  end

  table.sort(candidates, function(a, b)
    if a.priority ~= b.priority then return a.priority > b.priority end
    return a.size < b.size
  end)

  for _, candidate in ipairs(candidates) do
    local symbol = candidate.symbol
    local new_path = vim.list_extend({}, path)
    table.insert(new_path, {
      name = symbol.name,
      kind = symbol.kind,
    })

    local current_priority = candidate.priority

    if symbol.children and #symbol.children > 0 then
      local child_path = find_symbols_at_position(symbol.children, row, col, new_path)
      if #child_path > #best_path then
        best_path = child_path
        best_priority = current_priority
      elseif #child_path == #best_path and current_priority > best_priority then
        best_path = child_path
        best_priority = current_priority
      end
    else
      if #new_path > #best_path then
        best_path = new_path
        best_priority = current_priority
      elseif #new_path == #best_path and current_priority > best_priority then
        best_path = new_path
        best_priority = current_priority
      end
    end
  end

  return best_path
end

local function is_valid_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if not vim.bo[bufnr].buflisted then return false end
  local buftype = vim.bo[bufnr].buftype
  if buftype ~= "" then return false end

  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(win) then
    local height = vim.api.nvim_win_get_height(win)
    if height < 3 then return false end
  end

  return true
end

---@param bufnr number Buffer number
local function has_document_symbol_support(bufnr)
  return Utils.lsp.has(bufnr, "documentSymbol")
end

---@param callback function Callback to execute with symbols
local function get_lsp_symbols(callback)
  local bufnr = Utils.ensure_buf(0)
  if not has_document_symbol_support(bufnr) then
    callback(nil)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

  if
    cache.bufnr == bufnr
    and cache.row == row
    and cache.col == col
    and cache.changedtick == changedtick
    and cache.symbols ~= nil
  then
    callback(cache.symbols)
    return
  end

  if requesting then
    if cache.symbols then
      callback(cache.symbols)
    else
      callback(nil)
    end
    return
  end

  requesting = true
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
  }

  local cb = callback

  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result, _, _)
    requesting = false

    local symbols = nil
    if not err and result and #result > 0 then symbols = find_symbols_at_position(result, row, col) end

    cache.bufnr = bufnr
    cache.row = row
    cache.col = col
    cache.changedtick = changedtick
    cache.symbols = symbols

    if cb then cb(symbols) end
  end)
end

local function build_breadcrumb(symbols)
  if not symbols or #symbols == 0 then return " " end

  local display_symbols = symbols
  if M.config.max_depth and #symbols > M.config.max_depth then
    display_symbols = {}
    for i = #symbols - M.config.max_depth + 1, #symbols do
      table.insert(display_symbols, symbols[i])
    end
  end

  local parts = {}
  for _, symbol in ipairs(display_symbols) do
    local kind_name = vim.lsp.protocol.SymbolKind[symbol.kind] or "Unknown"
    local icon, hl = get_icon(kind_name, symbol.kind)

    local part = string.format("%%#%s#%s%%#Normal# %s", hl, icon, symbol.name)
    table.insert(parts, part)
  end

  local breadcrumb = table.concat(parts, M.config.separator)

  local win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then return breadcrumb end

  local win_width = vim.api.nvim_win_get_width(win)
  local available_width = win_width - M.config.padding.left - M.config.padding.right

  local plain_text = breadcrumb:gsub("%%#[^#]+#", "")

  if #plain_text > available_width then
    local truncated = {}
    local current_len = 3 -- Reserve space for "..."

    for i = #parts, 1, -1 do
      local plain_part = parts[i]:gsub("%%#[^#]+#", "")
      local part_len = #plain_part

      if i < #parts then part_len = part_len + #M.config.separator end

      if current_len + part_len <= available_width then
        table.insert(truncated, 1, parts[i])
        current_len = current_len + part_len
      else
        break
      end
    end

    if #truncated < #parts and #truncated > 0 then table.insert(truncated, 1, "...") end

    breadcrumb = table.concat(truncated, M.config.separator)
  end

  return breadcrumb
end

local function render_breadcrumb(symbols)
  if not is_valid_buffer() then return end
  pcall(function()
    local breadcrumb = build_breadcrumb(symbols)
    local left_pad = string.rep(" ", M.config.padding.left)
    local right_pad = string.rep(" ", M.config.padding.right)
    vim.wo.winbar = left_pad .. breadcrumb .. right_pad
  end)
end

-- Update winbar
function M.update()
  if not is_valid_buffer() then return end

  get_lsp_symbols(function(symbols)
    render_breadcrumb(symbols)
  end)
end

local function debounced_update()
  if debounce_timer then debounce_timer:stop() end

  debounce_timer = vim.defer_fn(function()
    M.update()
  end, M.config.debounce_ms)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local breadcrumb_hl = {
    BreadcrumbsFile = { link = "Directory" },
    BreadcrumbsModule = { link = "Include" },
    BreadcrumbsNamespace = { link = "Include" },
    BreadcrumbsPackage = { link = "Include" },
    BreadcrumbsClass = { link = "Type" },
    BreadcrumbsMethod = { link = "Function" },
    BreadcrumbsProperty = { link = "Identifier" },
    BreadcrumbsField = { link = "Identifier" },
    BreadcrumbsConstructor = { link = "Special" },
    BreadcrumbsEnum = { link = "Type" },
    BreadcrumbsInterface = { link = "Type" },
    BreadcrumbsFunction = { link = "Function" },
    BreadcrumbsVariable = { link = "Identifier" },
    BreadcrumbsConstant = { link = "Constant" },
    BreadcrumbsString = { link = "String" },
    BreadcrumbsNumber = { link = "Number" },
    BreadcrumbsBoolean = { link = "Boolean" },
    BreadcrumbsArray = { link = "Type" },
    BreadcrumbsObject = { link = "Type" },
    BreadcrumbsKey = { link = "Identifier" },
    BreadcrumbsNull = { link = "Comment" },
    BreadcrumbsEnumMember = { link = "Constant" },
    BreadcrumbsStruct = { link = "Structure" },
    BreadcrumbsEvent = { link = "Special" },
    BreadcrumbsOperator = { link = "Operator" },
    BreadcrumbsTypeParameter = { link = "Type" },
  }

  Utils.hl.add_highlights(breadcrumb_hl)

  Utils.autocmd.autocmd_augroup("breadcrumbs", {
    {
      events = { "CursorMoved" },
      callback = function()
        if not is_valid_buffer() then return end
        debounced_update()
      end,
    },
    {
      events = { "BufEnter", "LspAttach" },
      callback = function(event)
        local bufnr = event.buf
        if not is_valid_buffer(bufnr) then return end
        cache = { bufnr = nil, row = nil, col = nil, changedtick = nil, symbols = nil }
        M.update()
      end,
    },
    {
      events = { "FileType" },
      pattern = { "help", "terminal", "qf", "prompt" },
      callback = function()
        vim.wo.winbar = ""
      end,
    },
  })
end

return M
