---@class utils.treesitter
local M = {}
M.incr = {}
local incr = require("utils.treesitter.incr")

-------------------------------------------------
---Only checks whether treesitter highlighting is active in `buf`
---Should be faster than `M.is_active()`
---@param buf number? # default: current buffer
---@return boolean
-------------------------------------------------
function M.hl_is_active(buf)
  buf = Utils.ensure_list(buf)
  return vim.treesitter.highlighter.active[buf] ~= nil
end

-------------------------------------------------
---Returns whether treesitter is active in `buf`
---@param buf number? default: current buffer
---@return boolean
-------------------------------------------------
function M.is_active(buf)
  buf = Utils.ensure_buf(buf)
  if vim.treesitter.highlighter.active[buf] then return true end

  -- `vim.treesitter.get_parser()` can be slow for big files
  if not vim.b.bigfile and (pcall(vim.treesitter.get_parser, buf)) then return true end

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
  if not M.is_active(opts and opts.bufnr) then return end

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
    if check_type_match(nt) then return node end
    node = node:parent()
  end
end

M._installed = nil ---@type table<string,string>?

-----------------------------------------
---Get list of installed treesitter parsers
---@param force boolean?
---@return table<string,string>
-----------------------------------------
function M.get_installed(force)
  if not M._installed or force then
    M._installed = {}
    for _, lang in ipairs(require("nvim-treesitter").get_installed("parsers")) do
      M._installed[lang] = lang
    end
  end
  return M._installed
end

-----------------------------------------
---Check if treesitter parser is available for filetype
---@param ft string # filetype
---@return string?
-----------------------------------------
function M.have(ft)
  if not ft or ft == "" then return nil end
  local lang = vim.treesitter.language.get_lang(ft)
  return lang and M.get_installed()[lang]
end

function M.foldexpr()
  local buf = vim.api.nvim_get_current_buf()
  return M.have(vim.b[buf].filetype) and vim.treesitter.foldexpr() or "0"
end

function M.indentexpr()
  local buf = vim.api.nvim_get_current_buf()
  return M.have(vim.b[buf].filetype) and require("nvim-treesitter").indentexpr() or -1
end

---Ensure treesitter is active and parser is available
---@param buf number?
---@param language string?
---@return boolean, number?, string?
local function ensure_active(buf, language)
  buf = Utils.ensure_buf(buf)
  if not M.is_active(buf) then return false end
  language = language or vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not language or not M.have(vim.bo[buf].filetype) then return false end
  return true, buf, language
end

-------------------------------------------------
---Start incremental selection from the node under cursor
---@param buf number? # default: current buffer
---@param language string? # language (will be inferred if not provided)
-------------------------------------------------
function M.incr.init_selection(buf, language)
  local success, bufnr, lang = ensure_active(buf, language)
  if success then return incr.init_selection(bufnr, lang) end
end

-------------------------------------------------
---Expand selection to parent node
---@param buf number? # default: current buffer
---@param language string? # language (will be inferred if not provided)
-------------------------------------------------
function M.incr.node_incremental(buf, language)
  local success, bufnr, lang = ensure_active(buf, language)
  if success then return incr.node_incremental(bufnr, lang) end
end

-------------------------------------------------
---Expand selection to surrounding scope
---@param buf number? # default: current buffer
---@param language string? # language (will be inferred if not provided)
-------------------------------------------------
function M.incr.scope_incremental(buf, language)
  local success, bufnr, lang = ensure_active(buf, language)
  if success then return incr.scope_incremental(bufnr, lang) end
end

-------------------------------------------------
---Shrink selection to previous node
---@param buf number? # default: current buffer
---@param language string? # language (will be inferred if not provided)
-------------------------------------------------
function M.incr.node_decremental(buf, language)
  local success, bufnr, _ = ensure_active(buf, language)
  if success then return incr.node_decremental(bufnr) end
end

return M
