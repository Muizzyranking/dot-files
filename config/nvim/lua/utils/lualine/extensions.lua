local M = {}
local utils = require("utils.lualine.utils")
local get_telescope_prompt = utils.get_telescope_prompt
local get_telescope_num = utils.get_telescope_num

M.telescope = function()
  return {
    sections = {
      lualine_a = { get_telescope_prompt },
      lualine_b = { get_telescope_num },
    },
    filetypes = { "TelescopePrompt" },
  }
end

return M
