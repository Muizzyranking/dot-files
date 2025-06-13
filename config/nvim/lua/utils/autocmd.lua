---@class utils.autocmd
local M = setmetatable({}, {
  __call = function(m, event, opts)
    return m.create(event, opts)
  end,
})

-----------------------------------------------------------------------------
---@param name string|number
---@param opts? table
---@return number
-----------------------------------------------------------------------------
function M.augroup(name, opts)
  if type(name) == "number" then
    return name
  end
  opts = opts or {}
  name = "Neovim_" .. name
  opts.clear = opts.clear ~= false
  return vim.api.nvim_create_augroup(name, opts)
end

--------------------------------------------------------------------------
---@param name string
---@param autocmds autocmd.Create[]
---@param events string|string[]
--------------------------------------------------------------------------
function M.autocmd_augroup(name, autocmds, events)
  local group = M.augroup(name)
  for _, au in ipairs(autocmds) do
    local autocmd_events = au.events or events
    au.events = nil
    if autocmd_events then
      au.callback = au.callback or function()
        if au.cmd then
          vim.cmd(au.cmd)
        end
      end
      au.group = group
      vim.api.nvim_create_autocmd(autocmd_events, au)
    else
      Utils.notify.error("No events specified for autocmd in group: " .. name)
    end
  end
end

--------------------------------------------------------------------------
-- create an autocmd
---@param event string|string[]
---@param opts? autocmd.Create
--------------------------------------------------------------------------
function M.create(event, opts)
  opts = opts or {}
  if not opts.callback and not opts.cmd then
    Utils.notify.error("No callback or cmd provided for autocmd")
    return
  end
  event = Utils.ensure_list(event)
  local group = opts.group and M.augroup(opts.group)
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

  for key, value in pairs(opts) do
    if args[key] == nil then
      args[key] = value
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
  group = group and M.augroup(group) or nil
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
