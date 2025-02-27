---@class utils.ts
local M = {}

------------------------------------------------
-- from https://github.com/Bekaboo/dot/blob/master/.config/nvim/lua/utils/ts.lua
---Returns whether treesitter is active in `buf`
---@param buf integer? default: current buffer
---@return boolean
------------------------------------------------
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

  return false
end

------------------------------------------------
---Returns whether cursor is in a specific type of treesitter node
---@param types string|string[]|fun(types: string|string[]): boolean type of node, or function to check node type
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
    if type(types) == "string" then
      types = { types }
    end
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
