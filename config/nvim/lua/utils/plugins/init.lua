---@class utils.plugins
---@field lualine utils.plugin.lualine
local M = {}

setmetatable(M, {
  __index = function(t, k)
    t[k] = require("utils.plugins." .. k)
    return t[k]
  end,
})

return M
