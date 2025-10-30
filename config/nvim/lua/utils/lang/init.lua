---@class utils.lang
---@field js_ts utils.lang.js_ts
---@field python utils.lang.python
local M = {}

setmetatable(M, {
  __index = function(t, key)
    t[key] = require("utils.lang." .. key)
    return t[key]
  end,
})

return M
