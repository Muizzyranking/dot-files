local M = {}

M.config = {
  separator = " > ",
  max_depth = nil, -- Maximum depth of breadcrumbs (nil = unlimited)
  use_treesitter = true, -- Set to false to disable treesitter fallback
  debounce_ms = 100, -- Debounce delay for cursor movement
  padding = {
    left = 1,
    right = 1,
  },
}

-- Cache
local cache = {
  bufnr = nil,
  row = nil,
  symbols = nil,
}

-- Debounce timer
local debounce_timer = nil

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

local function find_symbols_at_position(symbols, row, path)
  path = path or {}
  for _, symbol in ipairs(symbols) do
    local range = symbol.range or symbol.location.range
    local start_line = range.start.line
    local end_line = range["end"].line

    if start_line <= row and row <= end_line then
      local new_path = vim.list_extend({}, path)
      table.insert(new_path, {
        name = symbol.name,
        kind = symbol.kind,
      })

      if symbol.children then
        local child_path = find_symbols_at_position(symbol.children, row, new_path)
        if child_path then return child_path end
      end

      return new_path
    end
  end
  return path
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

local function has_document_symbol_support(bufnr)
  return Utils.lsp.has(bufnr, "documentSymbol")
end

local function get_lsp_symbols(callback)
  local bufnr = Utils.ensure_buf(0)
  if not has_document_symbol_support(bufnr) then
    callback(nil)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1

  if cache.bufnr == bufnr and cache.row == row and cache.symbols then
    callback(cache.symbols)
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
  }

  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, function(err, result, _, _)
    if err or not result or #result == 0 then
      callback(nil)
      return
    end

    local symbols = find_symbols_at_position(result, row)

    cache.bufnr = bufnr
    cache.row = row
    cache.symbols = symbols

    callback(symbols)
  end)
end

local function get_treesitter_symbols()
  if not M.config.use_treesitter then return nil end

  local bufnr = vim.api.nvim_get_current_buf()

  if not Utils.treesitter.is_active(bufnr) then return nil end

  local cursor = vim.api.nvim_win_get_cursor(0)

  -- Use Utils.treesitter.get_node if available
  local node = Utils.treesitter.get_node({ bufnr = bufnr })

  if not node then return nil end

  local symbols = {}
  while node do
    local type = node:type()
    if type:match("function") or type:match("method") or type:match("class") then
      local name_node = node:field("name")[1]
      if name_node then
        local ok_text, name = pcall(vim.treesitter.get_node_text, name_node, bufnr)
        if ok_text and name then
          table.insert(symbols, 1, {
            name = name,
            kind = type:match("class") and 5 or 6,
          })
        end
      end
    end
    node = node:parent()
  end

  return #symbols > 0 and symbols or nil
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
    if not symbols then symbols = get_treesitter_symbols() end
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
        cache = { bufnr = nil, row = nil, symbols = nil }
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
