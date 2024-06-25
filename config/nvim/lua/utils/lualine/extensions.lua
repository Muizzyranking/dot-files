local M = {}
local lualine_utils = require("utils.lualine.utils")
local get_telescope_prompt = lualine_utils.get_telescope_prompt
local get_telescope_num = lualine_utils.get_telescope_num

M.telescope = function()
  local ret = {
    sections = {
      lualine_a = { get_telescope_prompt },
      lualine_b = { get_telescope_num },
    },
    filetypes = { "TelescopePrompt" },
  }
  return ret
end

M.toggleterm = function()
  return {
    sections = {
      lualine_a = {
        function()
          return " Terminal"
        end,
      },
    },
    filetypes = { "myterm" },
  }
end

M.lazygit = function()
  return {
    sections = {
      lualine_a = {
        function()
          return " Lazygit"
        end,
      },
    },
    filetypes = { "lazygit" },
  }
end

return M
