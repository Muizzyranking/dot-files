---@class utils.autocmd
local M = setmetatable({}, {
  __call = function(m, event, opts)
    return m.create(event, opts)
  end,
})

---@class utils.autocmd.autocmd
---@field events? string|string[]
---@field pattern string|string[]
---@field group string|integer
---@field callback fun(event: table)
---@field desc? string

-----------------------------------------------------------------------------
---@param name string
---@param opts? table
-----------------------------------------------------------------------------
function M.augroup(name, opts)
  opts = opts or {}
  name = "Neovim_" .. name
  opts.clear = opts.clear ~= false
  return vim.api.nvim_create_augroup(name, opts)
end

--------------------------------------------------------------------------
---@param name string
---@param autocmds utils.autocmd.autocmd[]
---@param events string|string[]
--------------------------------------------------------------------------
function M.autocmd_augroup(name, autocmds, events)
  local group = M.augroup(name)
  for _, au in ipairs(autocmds) do
    au.group = group
    local autocmd_events = au.events or events
    au.events = nil
    vim.api.nvim_create_autocmd(autocmd_events, {
      group = group,
      pattern = au.pattern,
      callback = au.callback,
      desc = au.desc,
      once = au.once,
    })
  end
end

---@class utils.autocmd.create
---@field callback? fun(event: table)
---@field cmd? string
---@field pattern? string|string[]
---@field group? string|integer
---@field once? boolean
---@field desc? string

--------------------------------------------------------------------------
-- create an autocmd
---@param event string|string[]
--- @param opts? utils.autocmd.create
--------------------------------------------------------------------------
function M.create(event, opts)
  opts = opts or {}
  event = Utils.ensure_list(event)
  local group = opts.group and (type(opts.group) == "string" and M.augroup(opts.group) or opts.group) or nil
  local once = opts.once
  local desc = opts.desc
  local pattern = opts.pattern
  local callback = opts.callback or function()
    vim.cmd(opts.cmd or "")
  end

  return vim.api.nvim_create_autocmd(event, {
    pattern = pattern,
    group = group,
    callback = callback,
    once = once,
    desc = desc,
  })
end

--------------------------------------------------------------------------
-- Trigger a user event
---@param pattern string|string[]
---@param opts? table
--------------------------------------------------------------------------
function M.exec_user_event(pattern, opts)
  opts = opts or {}
  local args = {}
  args.pattern = Utils.ensure_list(pattern)
  args.modeline = opts.modeline or false
  args.data = opts.data or {}

  for _, v in ipairs(opts) do
    if args[v] == nil then
      args[v] = opts[v]
    end
  end

  vim.api.nvim_exec_autocmds("User", args)
end

--------------------------------------------------------------------------
-- Execute a user-defined event
---@param patterns string|string[]
---@param fn fun(event: table)
---@param group? string|integer
---@return number # autocmd ID
--------------------------------------------------------------------------
function M.on_user_event(patterns, fn, group)
  if group and type(group) ~= "number" then
    group = M.augroup(group)
  end
  patterns = Utils.ensure_list(patterns)
  return vim.api.nvim_create_autocmd("User", {
    pattern = patterns,
    group = group or nil,
    callback = function(event)
      fn(event)
    end,
  })
end

--------------------------------------------------------------------------
-- lazily execute a function
---@param fn function
---@param group? string|integer
--------------------------------------------------------------------------
function M.on_very_lazy(fn, group)
  M.on_user_event("VeryLazy", fn, group)
end

return M
