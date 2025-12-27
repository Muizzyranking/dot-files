---@class utils.lang
---@field ts utils.lang.ts
---@field py utils.lang.py
local M = {}

setmetatable(M, {
  __index = function(t, k)
    local ok, mod = pcall(require, "utils.lang." .. k)
    if ok then
      t[k] = mod
      return t[k]
    end
    return nil
  end,
})

return M
