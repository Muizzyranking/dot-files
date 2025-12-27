-- copied from https://github.com/xyven1/neovim-config/blob/master/lua/config/lazyfile.lua
local M = {}

M.lazy_file_events = { "BufReadPost", "BufNewFile", "BufWritePre" }

function M.setup()
  M.lazy_file()
end

function M.lazy_file()
  local Event = require("lazy.core.handler.event")

  Event.mappings.LazyFile = { id = "LazyFile", event = M.lazy_file_events }
  Event.mappings["User LazyFile"] = Event.mappings.LazyFile
end

return M
