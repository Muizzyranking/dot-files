---@class utils.git
---@field conflict utils.git.conflict
local M = {}

setmetatable(M, {
  __index = function(t, k)
    t[k] = require("utils.git." .. k)
    return t[k]
  end,
})

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", {}, opts or {})
  require("utils.git.conflict").setup(opts)
  -- require("utils.git.commits").setup(opts)
  require("utils.git.stage").setup()
  require("utils.git.scratch").setup()
  -- require("utils.git.branch").setup(opts)
end

return M
