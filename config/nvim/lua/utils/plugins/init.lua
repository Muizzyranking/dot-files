---@class utils.plugins
---@field lualine utils.plugin.lualine
---@field sidekick utils.plugins.sidekick
local M = {}

setmetatable(M, {
  __index = function(t, k)
    t[k] = require("utils.plugins." .. k)
    return t[k]
  end,
})

return M
