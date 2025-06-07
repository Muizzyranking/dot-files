---@class utils.autocmd
local M = setmetatable({}, {
  __call = function(m, event, opts)
    return m.create(event, opts)
  end,
})

---@class autocmd
---@field events? string|string[]
---@field pattern string|string[]
---@field group string|integer
---@field callback fun(event: table)
---@field desc? string

---@param name string
---@param opts? table
function M.augroup(name, opts)
  opts = opts or {}
  name = "Neovim_" .. name
  opts.clear = opts.clear ~= false
  return vim.api.nvim_create_augroup(name, opts)
end

---@param name string
---@param autocmds autocmd[]
---@param events string|string[]
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

function M.create(event, opts)
  opts = opts or {}
  event = Utils.ensure_list(event)
  local group = opts.group and M.augroup(opts.group, {})
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

---@param pattern string|string[]
---@param opts? table
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

function M.on_user_event(pattern, opts)
  pattern = Utils.ensure_list(pattern)
  return M.create("User", {
    pattern = pattern,
    callback = opts.callback,
    desc = opts and opts.desc or "User event handler",
  })
end

return M
