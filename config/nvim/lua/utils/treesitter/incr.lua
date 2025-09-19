---@class utils.treesitter.incr
local M = {}

-- Node stack for tracking selection history per buffer
local nodes_stack = {} ---@type table<number, TSNode[]>

-----------------------------------------
-- Range utility functions
---@class Range
---@field range number[] 0-based inclusive range [start_row, start_col, end_row, end_col]
-----------------------------------------
local Range = {}
Range.__index = Range

-----------------------------------------
---@param range number[] 0-based inclusive range
---@return Range
-----------------------------------------
function Range.new(range)
  local self = setmetatable({}, Range)
  self.range = range -- 0-based inclusive
  return self
end

-----------------------------------------
---Create Range from TSNode
---@param node TSNode
---@return Range
-----------------------------------------
function Range.node(node)
  local srow, scol, erow, ecol = node:range()
  -- handle: 0-indexed exclusive (unaligned)
  if ecol == 0 then
    -- ending at the start of a row requires moving to the end of the
    -- previous row to ensure result is aligned to end of line
    erow = erow - 1
    local line = vim.api.nvim_buf_get_lines(0, erow, erow + 1, false)[1]
    ecol = math.max(#line, 1)
  end
  -- convert: 0-indexed exclusive -> 0-indexed inclusive (aligned)
  ecol = ecol - 1
  return Range.new({ srow, scol, erow, ecol })
end

-----------------------------------------
---Create Range from current visual selection
---@return Range
-----------------------------------------
function Range.visual()
  local _, srow, scol, _ = unpack(vim.fn.getpos("."))
  local _, erow, ecol, _ = unpack(vim.fn.getpos("v"))
  -- convert: 1-indexed inclusive -> 0-indexed inclusive
  srow = srow - 1
  scol = scol - 1
  erow = erow - 1
  ecol = ecol - 1

  if srow < erow or (srow == erow and scol <= ecol) then
    return Range.new({ srow, scol, erow, ecol })
  else
    return Range.new({ erow, ecol, srow, scol })
  end
end

-----------------------------------------
---Check if two ranges are the same
---@param other Range
---@return boolean
-----------------------------------------
function Range:same(other)
  return vim.deep_equal(self.range, other.range)
end

-----------------------------------------
---Get start position for vim.fn.setpos()
---@return number[]
-----------------------------------------
function Range:pos_start()
  return { 0, self.range[1] + 1, self.range[2] + 1, 0 }
end

-----------------------------------------
---Get end position for vim.fn.setpos()
---@return number[]
-----------------------------------------
function Range:pos_end()
  return { 0, self.range[3] + 1, self.range[4] + 1, 0 }
end

-----------------------------------------
---Convert to treesitter range format (0-indexed exclusive)
---@return number[]
-----------------------------------------
function Range:ts()
  -- convert: 0-indexed inclusive -> 0-indexed exclusive
  return { self.range[1], self.range[2], self.range[3], self.range[4] + 1 }
end

-----------------------------------------
-- Node stack management
---Push node to selection history stack
---@param buf number
---@param node TSNode
-----------------------------------------
local function push_node(buf, node)
  if not nodes_stack[buf] then nodes_stack[buf] = {} end
  table.insert(nodes_stack[buf], node)
end

-----------------------------------------
---Pop node from selection history stack
---@param buf number
---@return TSNode?
-----------------------------------------
local function pop_node(buf)
  if not nodes_stack[buf] or #nodes_stack[buf] == 0 then return nil end
  return table.remove(nodes_stack[buf])
end

-----------------------------------------
---Get last node from selection history stack
---@param buf number
---@return TSNode?
-----------------------------------------
local function last_node(buf)
  if not nodes_stack[buf] or #nodes_stack[buf] == 0 then return nil end
  return nodes_stack[buf][#nodes_stack[buf]]
end

-----------------------------------------
---Clear selection history for buffer
---@param buf number
-----------------------------------------
local function clear_nodes(buf)
  nodes_stack[buf] = {}
end

-----------------------------------------
---Parse buffer with treesitter
---@param buf number
---@param language string
---@return vim.treesitter.LanguageTree?
-----------------------------------------
local function parse_buffer(buf, language)
  local has, parser = pcall(vim.treesitter.get_parser, buf, language)
  if not has or not parser then return nil end
  -- Parse visible range for performance
  local first, last = vim.fn.line("w0"), vim.fn.line("w$")
  parser:parse({ first - 1, last })
  return parser
end

-----------------------------------------
---Select given node in visual mode
---@param node TSNode
-----------------------------------------
local function select_node(node)
  local range = Range.node(node)
  vim.fn.setpos("'<", range:pos_start())
  vim.fn.setpos("'>", range:pos_end())
  vim.cmd.normal({ "gv", bang = true })
end

-----------------------------------------
---Check if language has specific query file
---@param language string
---@param name string
---@return boolean
-----------------------------------------
local function has_query(language, name)
  return #vim.treesitter.query.get_files(language, name) > 0
end

-----------------------------------------
---Get scope nodes from treesitter locals query
---@param buf number
---@param language string
---@param root TSNode
---@return TSNode[]
-----------------------------------------
local function get_scopes(buf, language, root)
  if not has_query(language, "locals") then return {} end

  local query = vim.treesitter.query.get(language, "locals")
  if not query then return {} end

  local result = {}
  local start, _, stop, _ = root:range()

  for _, match in query:iter_matches(root, buf, start, stop + 1) do
    for id, nodes in pairs(match) do
      local capture = query.captures[id]
      if capture == "local.scope" then
        for _, node in ipairs(nodes) do
          table.insert(result, node)
        end
      end
    end
  end

  return result
end

----------------------------------------------------------------------------------
---Generic incremental selection function
---@param buf number
---@param language string
---@param parent_func fun(parser: vim.treesitter.LanguageTree, node: TSNode): TSNode?
----------------------------------------------------------------------------------
local function incremental_selection(buf, language, parent_func)
  local parser = parse_buffer(buf, language)
  if not parser then return end

  local range = Range.visual()
  local last = last_node(buf)
  local node = nil

  if not last or not range:same(Range.node(last)) then
    -- Handle re-initialization
    node = parser:named_node_for_range(range:ts(), {
      ignore_injections = false,
    })
    clear_nodes(buf)
  else
    -- Iterate through parent parsers and nodes until we find a node with
    -- a different range
    parser = parser:language_for_range(range:ts())
    while parser and not node do
      node = parser:named_node_for_range(range:ts())
      while node and range:same(Range.node(node)) do
        node = parent_func(parser, node)
      end
      parser = parser:parent()
    end
  end

  if node then
    push_node(buf, node)
    select_node(node)
  end
end

-------------------------------------------------
---Start incremental selection from the node under cursor
---@param buf number
---@param language string
-------------------------------------------------
function M.init_selection(buf, language)
  local parser = parse_buffer(buf, language)
  if not parser then return end

  local node = vim.treesitter.get_node({
    bufnr = buf,
    ignore_injections = false,
  })

  if node then
    push_node(buf, node)
    select_node(node)
  end
end

-------------------------------------------------
---Expand selection to parent node
---@param buf number
---@param language string
-------------------------------------------------
function M.node_incremental(buf, language)
  incremental_selection(buf, language, function(parser, node)
    return node:parent()
  end)
end

-------------------------------------------------
---Expand selection to surrounding scope
---@param buf number
---@param language string
-------------------------------------------------
function M.scope_incremental(buf, language)
  incremental_selection(buf, language, function(parser, node)
    if language ~= parser:lang() then
      -- Only handle scope for root language
      return nil
    end

    local scopes = get_scopes(buf, language, parser:trees()[1]:root())
    if #scopes == 0 then return nil end

    local result = node:parent()
    while result and not vim.tbl_contains(scopes, result) do
      result = result:parent()
    end

    assert(result ~= node, "infinite loop")
    return result
  end)
end

-------------------------------------------------
---Shrink selection to previous node
---@param buf number
-------------------------------------------------
function M.node_decremental(buf)
  local node = pop_node(buf)
  if node then select_node(node) end
end

vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    nodes_stack[args.buf] = nil
  end,
})

return M
