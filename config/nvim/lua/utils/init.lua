---@class utils
---@field actions utils.actions
---@field colors utils.colors
---@field fn utils.fn
---@field format utils.format
---@field hl utils.hl
---@field icons utils.icons
---@field lang utils.lang
---@field lazy utils.lazy
---@field lsp utils.lsp
---@field map utils.map
---@field notify utils.notify
---@field root utils.root
---@field treesitter utils.treesitter
local M = {}

setmetatable(M, {
  __index = function(t, k)
    local ok, module = pcall(require, "utils." .. k)
    if ok then
      t[k] = module
      return t[k]
    end
    return nil
  end,
})

return M
