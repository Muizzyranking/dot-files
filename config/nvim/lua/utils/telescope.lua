---@class utils.telescope
local M = {}

------------------------------------------------------------------------------
--- Opens selected Telescope entries in new buffers
---
--- This function does the following:
--- 1. Gets currently selected or multi-selected entries
--- 2. Closes the Telescope prompt
--- 3. Adds selected files to buffer list
--- 4. Switches to the last selected file's buffer
---
--- @param prompt_bufnr number The buffer number of the Telescope prompt
------------------------------------------------------------------------------
function M.open(prompt_bufnr)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local picker = action_state.get_current_picker(prompt_bufnr)
  local selections = picker:get_multi_selection()

  if picker.prompt_title:match("Files") then
    if #selections == 0 then
      table.insert(selections, action_state.get_selected_entry())
    end
    actions.close(prompt_bufnr)
    for _, selection in ipairs(selections) do
      if selection.filename and vim.fn.filereadable(selection.filename) == 1 then
        -- If it's a file and is readable, open it in a new buffer
        vim.cmd("badd " .. vim.fn.fnameescape(selection.filename))
      else
        -- Handle non-file entries gracefully
        vim.notify("Selection is not a valid file: " .. (selection.value or "unknown"), vim.log.levels.WARN)
      end
    end
    -- Focus on the last valid file if any were opened
    if
      #selections > 0
      and selections[#selections].filename
      and vim.fn.filereadable(selections[#selections].filename) == 1
    then
      vim.cmd("buffer " .. vim.fn.fnameescape(selections[#selections].filename))
    end
  else
    actions.select_default(prompt_bufnr)
  end
end

------------------------------------------------------------------------------
-- Gets the current telescope prompt
---@return string?
------------------------------------------------------------------------------
function M.get_telescope_prompt()
  local ok, state = pcall(require, "telescope.actions.state")
  if not ok then
    return
  end
  local picker = state.get_current_picker(vim.api.nvim_get_current_buf())
  if not picker then
    return
  end
  local prompt_title = picker.prompt_title or "Telescope"
  return " " .. prompt_title
end

------------------------------------------------------------------------------
-- Gets the total number of telescope results
---@return string?
------------------------------------------------------------------------------
function M.get_telescope_num()
  local ok, state = pcall(require, "telescope.actions.state")
  if not ok then
    return
  end
  local picker = state.get_current_picker(vim.api.nvim_get_current_buf())
  if not picker then
    return
  end
  local total_results = #picker.finder.results
  return "Total Results: " .. total_results
end

--- Lualine configuration specifically for Telescope prompts
M.lualine = {
  sections = {
    lualine_a = { M.get_telescope_prompt },
    lualine_b = { M.get_telescope_num },
  },
  filetypes = { "TelescopePrompt" },
}

return M
