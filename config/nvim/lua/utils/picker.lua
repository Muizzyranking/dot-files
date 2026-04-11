---@class utils.picker
---@field files fun(opts?: table)
---@field grep fun(opts?: table)
---@field buffers fun(opts?: table)
---@field recent fun(opts?: table)
---@field grep_word fun(opts?: table)
---@field grep_buffers fun(opts?: table)
---@field diagnostics fun(opts?: table)
---@field icons fun(opts?: table)
---@field man fun(opts?: table)
---@field resume fun(opts?: table)
---@field spelling fun(opts?: table)
---@field explorer fun(opts?: table)
---@field unsaved_buffers fun(opts?: table)
---@field get fun(opts?: table)
---@field [any] fun(opts?: table)
local M = {}

local function has_fff()
  return Utils.lazy.has("fff.nvim")
end

function M.files(opts)
  if has_fff() then
    Snacks.picker.fff(opts)
  else
    Snacks.picker.files(opts)
  end
end

function M.grep(opts)
  if has_fff() then
    Snacks.picker.fff_live_grep(opts)
  else
    Snacks.picker.grep(opts)
  end
end

return setmetatable(M, {
  __index = function(_, key)
    return Snacks.picker[key]
  end,
})
