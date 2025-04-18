local M = {}

-- Local variables
local config = {}
local files_module = nil

function M.setup(opts)
  config = opts
  files_module = require("bookmarks.files")
end

-- Update UI components
function M.update_status()
  pcall(function()
    require("lualine").refresh()
  end)
end

M.lualine_component = function()
  return {
    function()
      local buf = vim.api.nvim_get_current_buf()
      local bookmark_index = files_module.is_bookmarked(buf)

      if not bookmark_index then
        return ""
      end
      return config.icons.bookmark .. bookmark_index
    end,
    color = Utils.lualine.fg("DiagnosticOk"),
  }
end

return M
