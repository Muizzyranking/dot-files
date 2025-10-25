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
  if type(name) == "number" then return name end
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
  for _, opts in ipairs(autocmds) do
    if opts.merge_events == true then opts.events = vim.tbl_extend("force", {}, events or {}, opts.events or {}) end
    opts.merge_events = nil
    local autocmd_events = opts.events or events
    opts.events = nil
    if autocmd_events then
      opts.group = group
      M.create(autocmd_events, opts)
    else
      Utils.notify.error("No events specified for autocmd in group: " .. name)
    end
  end
end

--------------------------------------------------------------------------
-- create an autocmd
---@param event string|string[]
---@param opts? autocmd.Create
---@return number? # autocmd ID
--------------------------------------------------------------------------
function M.create(event, opts)
  opts = opts or {}
  if not opts.callback and not opts.cmd then
    Utils.notify.error("No callback or cmd provided for autocmd")
    return
  end
  event = Utils.ensure_list(event)
  local cmd = opts.cmd or ""
  opts.cmd = nil
  local auopts = {
    group = opts.group and M.augroup(opts.group),
    callback = opts.callback or function()
      if cmd then vim.cmd(cmd) end
    end,
  }
  for key, value in pairs(opts) do
    if auopts[key] == nil then auopts[key] = value end
  end

  return vim.api.nvim_create_autocmd(event, auopts)
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
    if args[key] == nil then args[key] = value end
  end

  vim.api.nvim_exec_autocmds("User", args)
end

--------------------------------------------------------------------------
-- Execute a user-defined event
---@param pattern string|string[]
---@param fn fun(event: table)
---@param opts? autocmd.Create
---@return number? # autocmd ID
--------------------------------------------------------------------------
function M.on_user_event(pattern, fn, opts)
  opts = opts or {}
  pattern = Utils.ensure_list(pattern)
  opts.pattern = pattern
  opts.callback = function(event)
    if Utils.type(fn, "function") then fn(event) end
  end
  return M.create("User", opts)
end

--------------------------------------------------------------------------
-- lazily execute a function
---@param fn function
---@param opts? table
--------------------------------------------------------------------------
function M.on_very_lazy(fn, opts)
  opts = opts or {}
  M.on_user_event("VeryLazy", fn, opts)
end

return M
