-- lualine_custom.lua
local M = {}

-- Check if lualine is available
local ok_lualine, lualine = pcall(require, "lualine")
if not ok_lualine then
  return M
end

-- Check if telescope is available
local ok_telescope, telescope = pcall(require, "telescope")
if not ok_telescope then
  return M
end

local telescope_prompt_title = ""
local telescope_result_count = 0

local function get_telescope_info()
  return telescope_prompt_title .. " (" .. telescope_result_count .. ")"
end

local function setup_telescope_hooks()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  telescope.setup({
    defaults = {
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:enhance({
          post = function()
            local picker = action_state.get_current_picker(prompt_bufnr)
            telescope_result_count = picker.stats.processed
            lualine.refresh()
          end,
        })
        return true
      end,
    },
  })

  local builtin = require("telescope.builtin")

  local pickers = {
    find_files = builtin.find_files,
    buffers = builtin.buffers,
    live_grep = builtin.live_grep,
    grep_string = builtin.grep_string,
    current_buffer_fuzzy_find = builtin.current_buffer_fuzzy_find,
  }

  for name, picker in pairs(pickers) do
    local original_picker = picker
    pickers[name] = function(...)
      telescope_prompt_title = name:gsub("_", " "):gsub("%f[%a]%w", string.upper)
      telescope_result_count = 0
      lualine.refresh()
      return original_picker(...)
    end
  end

  -- Replace the builtin pickers with the hooked ones
  for name, picker in pairs(pickers) do
    builtin[name] = picker
  end
end

M.sections = {
  lualine_a = { "mode" },
  lualine_c = { get_telescope_info },
}

M.filetypes = { "TelescopePrompt" }

setup_telescope_hooks()

return M
