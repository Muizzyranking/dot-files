---@class utils.ts
local M = {}

-------------------------------------------------
---Only checks whether treesitter highlighting is active in `buf`
---Should be faster than `utils.ts.is_active()`
---@param buf number? # default: current buffer
---@return boolean
-------------------------------------------------
function M.hl_is_active(buf)
  if not buf or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  return vim.treesitter.highlighter.active[buf] ~= nil
end

-------------------------------------------------
---Returns whether treesitter is active in `buf`
---@param buf number? default: current buffer
---@return boolean
-------------------------------------------------
function M.is_active(buf)
  if not buf or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  if vim.treesitter.highlighter.active[buf] then
    return true
  end

  -- `vim.treesitter.get_parser()` can be slow for big files
  if not vim.b.bigfile and (pcall(vim.treesitter.get_parser, buf)) then
    return true
  end

  -- File is big or cannot get parser for buf
  return false
end

-------------------------------------------------
---Wrapper of `vim.treesitter.get_node()` that fixes the cursor pos in
---insert mode
---@param opts vim.treesitter.get_node.Opts?
-------------------------------------------------
function M.get_node(opts)
  opts = opts or {}
  if opts.pos or opts.bufnr and opts.bufnr ~= 0 and opts.bufnr ~= vim.api.nvim_get_current_buf() then
    return vim.treesitter.get_node(opts)
  end
  opts.pos = (function()
    local cursor = opts and opts.pos or vim.api.nvim_win_get_cursor(0)
    return {
      cursor[1] - 1,
      cursor[2] - (cursor[2] >= 1 and vim.startswith(vim.fn.mode(), "i") and 1 or 0),
    }
  end)()

  return vim.treesitter.get_node(opts)
end

------------------------------------------------
---Returns whether cursor is in a specific type of treesitter node
---@param types string|string[]|fun(types: string|string[]): boolean # type of node, or function to check node type
---@param opts vim.treesitter.get_node.Opts?
---@return TSNode?
------------------------------------------------
function M.find_node(types, opts)
  if not M.is_active(opts and opts.bufnr) then
    return
  end

  ---Check if given node type matches any of the types given in `types`
  ---@type fun(t: string): boolean?
  local check_type_match = vim.is_callable(types) and function(nt)
    return types(nt)
  end or function(nt)
    types = Utils.ensure_list(types)
    return vim.iter(types):any(function(t)
      return nt:match(t)
    end)
  end

  local node = M.get_node(opts)
  while node do
    local nt = node:type() -- current node type
    if check_type_match(nt) then
      return node
    end
    node = node:parent()
  end
end

return M
