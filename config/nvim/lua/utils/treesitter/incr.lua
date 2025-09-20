---@class utils.treesitter.incr
local M = {}

-- Node stack for tracking selection history per buffer
local nodes_stack = {} ---@type table<number, TSNode[]>

-----------------------------------------
-- Range utility class
---@class Range
---@field range number[] 0-based inclusive range [start_row, start_col, end_row, end_col]
-----------------------------------------
local Range = {}
Range.__index = Range

---@param range number[] 0-based inclusive range
---@return Range
function Range.new(range)
  return setmetatable({ range = range }, Range)
end

---Create Range from TSNode
---@param node TSNode
---@return Range
function Range.node(node)
  local srow, scol, erow, ecol = node:range()
  -- Handle 0-indexed exclusive (unaligned) to 0-indexed inclusive (aligned)
  if ecol == 0 then
    erow = erow - 1
    local line = vim.api.nvim_buf_get_lines(0, erow, erow + 1, false)[1]
    ecol = math.max(#line, 1)
  end
  ecol = ecol - 1
  return Range.new({ srow, scol, erow, ecol })
end

---Create Range from current visual selection
---@return Range
function Range.visual()
  local _, srow, scol, _ = unpack(vim.fn.getpos("."))
  local _, erow, ecol, _ = unpack(vim.fn.getpos("v"))
  -- Convert 1-indexed inclusive to 0-indexed inclusive
  srow, scol, erow, ecol = srow - 1, scol - 1, erow - 1, ecol - 1

  -- Ensure proper order
  if srow > erow or (srow == erow and scol > ecol) then
    srow, scol, erow, ecol = erow, ecol, srow, scol
  end

  return Range.new({ srow, scol, erow, ecol })
end

---Check if two ranges are the same
---@param other Range
---@return boolean
function Range:same(other)
  return vim.deep_equal(self.range, other.range)
end

---Get position table for vim.fn.setpos()
---@param is_end boolean
---@return number[]
function Range:pos(is_end)
  local idx = is_end and 3 or 1
  local col_idx = is_end and 4 or 2
  return { 0, self.range[idx] + 1, self.range[col_idx] + 1, 0 }
end

---Convert to treesitter range format (0-indexed exclusive)
---@return number[]
function Range:ts()
  return { self.range[1], self.range[2], self.range[3], self.range[4] + 1 }
end

-----------------------------------------
-- Stack management utilities
-----------------------------------------
local StackManager = {}

function StackManager.ensure_stack(buf)
  if not nodes_stack[buf] then nodes_stack[buf] = {} end
end

function StackManager.push(buf, node)
  StackManager.ensure_stack(buf)
  table.insert(nodes_stack[buf], node)
end

function StackManager.pop(buf)
  if not nodes_stack[buf] or #nodes_stack[buf] == 0 then return nil end
  return table.remove(nodes_stack[buf])
end

function StackManager.peek(buf)
  if not nodes_stack[buf] or #nodes_stack[buf] == 0 then return nil end
  return nodes_stack[buf][#nodes_stack[buf]]
end

function StackManager.clear(buf)
  nodes_stack[buf] = {}
end

function StackManager.is_valid_chain(buf, current_range)
  local last_node = StackManager.peek(buf)
  return last_node and current_range:same(Range.node(last_node))
end

-----------------------------------------
-- Parser utilities
-----------------------------------------
local ParserUtils = {}

---Parse buffer with treesitter
---@param buf number
---@param language string
---@return vim.treesitter.LanguageTree?
function ParserUtils.get_parser(buf, language)
  local has, parser = pcall(vim.treesitter.get_parser, buf, language)
  if not has or not parser then return nil end
  -- Parse visible range for performance
  local first, last = vim.fn.line("w0"), vim.fn.line("w$")
  parser:parse({ first - 1, last })
  return parser
end

---Check if language has specific query file
---@param language string
---@param name string
---@return boolean
function ParserUtils.has_query(language, name)
  return #vim.treesitter.query.get_files(language, name) > 0
end

---Get scope nodes from treesitter locals query
---@param buf number
---@param language string
---@param root TSNode
---@return TSNode[]
function ParserUtils.get_scopes(buf, language, root)
  if not ParserUtils.has_query(language, "locals") then return {} end

  local query = vim.treesitter.query.get(language, "locals")
  if not query then return {} end

  local result = {}
  local start, _, stop, _ = root:range()

  for _, match in query:iter_matches(root, buf, start, stop + 1) do
    for id, nodes in pairs(match) do
      if query.captures[id] == "local.scope" then vim.list_extend(result, nodes) end
    end
  end

  return result
end

-----------------------------------------
-- Node selection utilities
-----------------------------------------
local NodeUtils = {}

---Select given node in visual mode
---@param node TSNode
function NodeUtils.select(node)
  local range = Range.node(node)
  vim.fn.setpos("'<", range:pos(false))
  vim.fn.setpos("'>", range:pos(true))
  vim.cmd.normal({ "gv", bang = true })
end

---Common delimiter patterns for initial node detection
local DELIMITER_PATTERNS = { "^%p$", "%(", "%)", "%[", "%]", "%{", "%}", '"', "'", "`", ",", ";", ":" }
local MEANINGFUL_CONTAINERS = {
  "list",
  "dict",
  "table",
  "array",
  "block",
  "expression",
  "statement",
  "call",
  "string",
}

---Check if node type matches any pattern in the list
---@param node_type string
---@param patterns string[]
---@return boolean
local function matches_any_pattern(node_type, patterns)
  for _, pattern in ipairs(patterns) do
    if node_type:match(pattern) then return true end
  end
  return false
end

---Find the most meaningful node for initial selection
---@param buf number
---@return TSNode?
function NodeUtils.find_initial(buf)
  local node = Utils.treesitter.get_node({ bufnr = buf })
  if not node then return nil end

  local node_type = node:type()

  -- Handle delimiter/bracket nodes - find containing structure
  if matches_any_pattern(node_type, DELIMITER_PATTERNS) then
    local parent = node:parent()
    while parent do
      if matches_any_pattern(parent:type(), MEANINGFUL_CONTAINERS) then return parent end
      parent = parent:parent()
    end
  end

  -- Handle identifiers in function contexts
  if node_type == "identifier" then
    local parent = node:parent()
    if parent and parent:type():match("function") then return node end
  end

  return node
end

---Find the immediate child node that contains the current selection
---@param buf number
---@param language string
---@param current_range Range
---@return TSNode?
function NodeUtils.find_child(buf, language, current_range)
  local parser = ParserUtils.get_parser(buf, language)
  if not parser then return nil end

  local current_node = parser:named_node_for_range(current_range:ts(), {
    ignore_injections = false,
  })
  if not current_node then return nil end

  local function find_smallest_child(node)
    for child in node:iter_children() do
      if child:named() then
        local child_range = Range.node(child)
        local child_ts, current_ts = child_range:ts(), current_range:ts()

        -- Check if child contains the current selection
        if
          child_ts[1] <= current_ts[1]
          and child_ts[2] <= current_ts[2]
          and child_ts[3] >= current_ts[3]
          and child_ts[4] >= current_ts[4]
          and not child_range:same(current_range)
        then
          return find_smallest_child(child) or child
        end
      end
    end
    return nil
  end

  return find_smallest_child(current_node)
end

-----------------------------------------
-- Core selection logic
-----------------------------------------
local SelectionCore = {}

---Generic incremental selection function
---@param buf number
---@param language string
---@param parent_func fun(parser: vim.treesitter.LanguageTree, node: TSNode): TSNode?
function SelectionCore.incremental(buf, language, parent_func)
  local parser = ParserUtils.get_parser(buf, language)
  if not parser then return end

  local range = Range.visual()
  local node = nil

  -- Check if this continues the current selection chain
  if StackManager.is_valid_chain(buf, range) then
    -- Continue with current chain
    parser = parser:language_for_range(range:ts())
    while parser and not node do
      node = parser:named_node_for_range(range:ts())
      while node and range:same(Range.node(node)) do
        node = parent_func(parser, node)
      end
      parser = parser:parent()
    end
  else
    -- Start new selection chain
    node = parser:named_node_for_range(range:ts(), { ignore_injections = false })
    StackManager.clear(buf)
  end

  if node then
    StackManager.push(buf, node)
    NodeUtils.select(node)
  end
end

---Parent node selection strategy
---@param parser vim.treesitter.LanguageTree
---@param node TSNode
---@return TSNode?
function SelectionCore.parent_strategy(parser, node)
  return node:parent()
end

---Scope-based selection strategy
---@param buf number
---@param language string
---@return fun(parser: vim.treesitter.LanguageTree, node: TSNode): TSNode?
function SelectionCore.scope_strategy(buf, language)
  return function(parser, node)
    if language ~= parser:lang() then return nil end -- Only handle root language scope

    local scopes = ParserUtils.get_scopes(buf, language, parser:trees()[1]:root())
    if #scopes == 0 then return nil end

    local result = node:parent()
    while result and not vim.tbl_contains(scopes, result) do
      result = result:parent()
    end

    assert(result ~= node, "infinite loop detected")
    return result
  end
end

-----------------------------------------
-- Public API
-----------------------------------------

---Start incremental selection from the smallest node under cursor
---@param buf number
---@param language string
function M.init_selection(buf, language)
  local parser = ParserUtils.get_parser(buf, language)
  if not parser then return end

  local node = NodeUtils.find_initial(buf)
  if node then
    StackManager.clear(buf)
    StackManager.push(buf, node)
    NodeUtils.select(node)
  end
end

---Expand selection to parent node
---@param buf number
---@param language string
function M.node_incremental(buf, language)
  SelectionCore.incremental(buf, language, SelectionCore.parent_strategy)
end

---Expand selection to surrounding scope
---@param buf number
---@param language string
function M.scope_incremental(buf, language)
  SelectionCore.incremental(buf, language, SelectionCore.scope_strategy(buf, language))
end

---Shrink selection to smaller node (proper decremental behavior)
---@param buf number
---@param language string
function M.node_decremental(buf, language)
  local current_range = Range.visual()

  -- Try to use selection chain history
  if StackManager.is_valid_chain(buf, current_range) then
    StackManager.pop(buf) -- Remove current
    local prev_node = StackManager.peek(buf)
    if prev_node then
      NodeUtils.select(prev_node)
      return
    end
  end

  -- Find largest child node as fallback
  local child_node = NodeUtils.find_child(buf, language, current_range)
  if child_node then
    StackManager.clear(buf)
    StackManager.push(buf, child_node)
    NodeUtils.select(child_node)
  end
end

-- Cleanup on buffer deletion
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    nodes_stack[args.buf] = nil
  end,
})

return M
