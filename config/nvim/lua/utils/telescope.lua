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

function M.multi_grep(opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local conf = require("telescope.config").values

  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local finder = finders.new_async_job({
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil
      end

      local pieces = vim.split(prompt, "  ")
      local args = { "rg" }
      if pieces[1] then
        table.insert(args, "-e")
        table.insert(args, pieces[1])
      end

      if pieces[2] then
        table.insert(args, "-g")
        table.insert(args, pieces[2])
      end

      ---@diagnostic disable-next-line: deprecated
      return vim.tbl_flatten({
        args,
        { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" },
      })
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  })

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = "Multi Grep",
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = require("telescope.sorters").empty(),
    })
    :find()
end

--- Lualine configuration specifically for Telescope prompts
M.lualine = {
  sections = {
    lualine_a = { M.get_telescope_prompt },
    lualine_b = { M.get_telescope_num },
  },
  filetypes = { "TelescopePrompt" },
}

local function get_root()
  return Utils.find_root_directory(0, { ".git", "lua" })
end

---@type table<string, table>
local themes = {
  wide_preview = {
    theme = "wide_preview",
    cwd = get_root(),
    layout_config = {
      preview_width = 0.6,
    },
  },
  dropdown = {
    theme = "dropdown",

    results_title = false,
    winblend = 0,
    previewer = false,

    sorting_strategy = "ascending",
    layout_strategy = "center",
    layout_config = {
      preview_cutoff = 1, -- Preview should always show (unless previewer = false)

      width = function(_, max_columns, _)
        return math.min(max_columns, 90)
      end,

      height = function(_, _, max_lines)
        return math.min(max_lines, 20)
      end,
    },

    border = true,
    borderchars = {
      prompt = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
      results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
      preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
    },
  },
  command_pane = {
    theme = "command_pane",
    previewer = false,
    prompt_title = false,
    results_title = false,
    sorting_strategy = "descending",
    layout_strategy = "bottom_pane",
    layout_config = {
      height = 13,
      preview_cutoff = 1,
      prompt_position = "bottom",
    },
  },
  ivy_plus = {
    theme = "ivy_plus",
    previewer = false,
    prompt_title = false,
    results_title = false,
    layout_strategy = "bottom_pane",
    layout_config = {
      height = 13,
      preview_cutoff = 120,
      prompt_position = "bottom",
    },
    borderchars = {
      prompt = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
      results = { "─", "│", "─", "│", "┌", "┬", "┴", "└" },
      preview = { "─", "│", " ", " ", "─", "┐", "│", " " },
    },
  },
}

---@param picker function The telescope picker function to run
---@param layout string The theme layout to use (must be a key in themes table)
---@param opts? table Optional settings to override theme defaults
---@return function
function M.layout(picker, layout, opts)
  opts = opts or {}
  if opts.cwd == false then
    opts.cwd = nil
  end
  return function()
    local theme = opts and vim.tbl_deep_extend("force", themes[layout], opts) or themes[layout]
    picker(theme)
  end
end

return M
