---@class utils.treesitter
local M = {}
M.incr = {}

-------------------------------------------------
---Only checks whether treesitter highlighting is active in `buf`
---Should be faster than `M.is_active()`
---@param buf number? # default: current buffer
---@return boolean
-------------------------------------------------
function M.hl_is_active(buf)
  buf = Utils.ensure_buf(buf)
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
---@return boolean, number?, string?
function M.incr.ensure_active()
  local buf = Utils.ensure_buf(0)
  if not M.is_active(buf) then return false end
  local language = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not language or not M.have(vim.bo[buf].filetype) then return false end
  return true, buf, language
end

M.incr.keymaps = {
  init_selection = nil,
  node_incremental = nil,
  scope_incremental = nil,
  node_decremental = nil,
}

M.incr.is_attached = false

function M.incr.attach(opts)
  if M.incr.is_attached then return end
  M.incr.is_attached = true
  local incr = require("utils.treesitter.incr")
  local i = M.incr
  opts = opts or {}
  M.incr.keymaps = vim.tbl_extend("force", {
    init_selection = "<CR>",
    node_incremental = "<CR>",
    scope_incremental = "w",
    node_decremental = "<BS>",
  }, opts.keymaps or {})

  local set = vim.keymap.set

  set("n", M.incr.keymaps.init_selection, function()
    local success, buf, lang = i.ensure_active()
    if success then return incr.init_selection(buf, lang) end
  end, { desc = "Init incremental selection" })

  set("x", M.incr.keymaps.node_incremental, function()
    local success, buf, lang = i.ensure_active()
    if success then return incr.node_incremental(buf, lang) end
  end, { desc = "Node incremental" })

  set("x", M.incr.keymaps.scope_incremental, function()
    local success, buf, lang = i.ensure_active()
    if success then return incr.scope_incremental(buf, lang) end
  end, { desc = "Scope incremental" })

  set("x", M.incr.keymaps.node_decremental, function()
    local success, bufnr, lang = i.ensure_active()
    if success then return incr.node_decremental(bufnr, lang) end
  end, { desc = "Node decremental" })
end

function M.incr.detach()
  if not M.incr.is_attached then return end
  pcall(vim.keymap.del, "n", M.incr.keymaps.init_selection)
  pcall(vim.keymap.del, "x", M.incr.keymaps.node_incremental)
  pcall(vim.keymap.del, "x", M.incr.keymaps.scope_incremental)
  pcall(vim.keymap.del, "x", M.incr.keymaps.node_decremental)
end

return M
