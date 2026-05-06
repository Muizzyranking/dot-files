---@class StatuslineCache
---Cache helper for statusline components.
---Each component owns its cache and declares what invalidates it.
local M = {}

---@class CacheOpts
---@field per_buf? boolean  Separate cache per buffer (default: false)

---@class CacheEvent
---@field event string
---@field pattern? string  Required for User events

---Create a cached component function.
---
---Events can be plain strings OR tables with { event, pattern } for User events:
---  cache({ "BufEnter", { event = "User", pattern = "GitSignsUpdate" } }, fn)
---
---@param events (string|CacheEvent)[]
---@param fn fun(): string
---@param opts? CacheOpts
---@return fun(): string
function M.cache(events, fn, opts)
  opts = opts or {}
  local per_buf = opts.per_buf or false

  ---@type table<integer, string>|{ value: string|nil }
  local store = per_buf and {} or { value = nil }
  local group = vim.api.nvim_create_augroup("statusline.cache." .. tostring(fn), { clear = true })

  local function invalidate(buf)
    if per_buf then
      if buf then
        store[buf] = nil
      else
        store = {}
      end
    else
      store.value = nil
    end
    vim.schedule(function()
      vim.cmd.redrawstatus()
    end)
  end

  for _, ev in ipairs(events) do
    if type(ev) == "string" then
      vim.api.nvim_create_autocmd(ev, {
        group = group,
        callback = function(e)
          invalidate(e.buf)
        end,
      })
    elseif type(ev) == "table" then
      vim.api.nvim_create_autocmd(ev.event, {
        group = group,
        pattern = ev.pattern,
        callback = function(e)
          invalidate(e.buf)
        end,
      })
    end
  end

  return function()
    if per_buf then
      local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
      if store[buf] == nil then
        store[buf] = fn()
      end
      return store[buf]
    else
      if store.value == nil then
        store.value = fn()
      end
      return store.value
    end
  end
end

return M
