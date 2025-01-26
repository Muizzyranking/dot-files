---@class utils.telescope
local M = setmetatable({}, {
  __call = function(m, picker, layout, opts)
    return function()
      m.wrap(picker, layout, opts)()
    end
  end,
})
M.pickers = {}

------------------------------------------------------------------------------
--- Opens selected Telescope entries in new buffers
---
--- This function does the following:
--- 1. Gets currently selected or multi-selected entries
--- 2. Closes the Telescope prompt
--- 3. Adds selected files to buffer list
--- 4. Switches to the first selected file's buffer
---
--- @param prompt_bufnr number The buffer number of the Telescope prompt
------------------------------------------------------------------------------
function M.open(prompt_bufnr)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local picker = action_state.get_current_picker(prompt_bufnr)
  local selections = picker:get_multi_selection()
  local entry_maker = picker._entry_makers and picker._entry_makers[1]
  local is_file_picker = entry_maker and entry_maker.display_items and entry_maker.display_items.path

  if #selections == 0 then
    selections = { action_state.get_selected_entry() }
  end

  if is_file_picker or selections[1].filename then
    actions.close(prompt_bufnr)
    local first_valid_file
    local first_valid_line
    local first_valid_col
    local positions = {}

    for _, selection in ipairs(selections) do
      local filename = selection.filename or selection.path
      if filename then
        filename = vim.fn.fnamemodify(filename, ":p")
        if vim.fn.filereadable(filename) == 1 then
          -- Add file to buffer list without switching to it
          vim.cmd.badd(vim.fn.fnameescape(filename))
          -- Get buffer number for the added file
          local bufnr = vim.fn.bufnr(filename)
          -- Mark this buffer as opened by telescope
          vim.api.nvim_buf_set_var(bufnr, "telescope_opened", true)

          -- Store position information for this buffer
          if selection.lnum then
            positions[bufnr] = {
              line = selection.lnum,
              col = selection.col or 0,
            }
          end

          -- Store first valid file and its position
          if not first_valid_file then
            first_valid_file = filename
            first_valid_line = selection.lnum
            first_valid_col = selection.col
          end
        else
          vim.notify(string.format("Cannot read file: %s", filename), vim.log.levels.WARN)
        end
      end
    end

    -- Set cursor position for all buffers
    for bufnr, pos in pairs(positions) do
      -- Get all windows displaying this buffer
      local wins = vim.fn.win_findbuf(bufnr)
      for _, win in ipairs(wins) do
        -- Set cursor position for each window
        vim.api.nvim_win_set_cursor(win, { pos.line, pos.col })
      end

      -- Also store the cursor position in the buffer variables
      -- This will be used when the buffer is displayed later
      vim.api.nvim_buf_set_var(bufnr, "telescope_cursor_pos", pos)
    end

    -- Switch to the first valid file if one was found
    if first_valid_file then
      vim.cmd.buffer(vim.fn.fnameescape(first_valid_file))
      -- Jump to the specific line and column if available
      if first_valid_line then
        vim.api.nvim_win_set_cursor(0, { first_valid_line, (first_valid_col or 0) })
        -- Center the cursor in the window
        vim.cmd("normal! zz")
      end
    end

    -- Set up an autocmd to restore cursor position when switching buffers
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = vim.api.nvim_create_augroup("TelescopeCursorRestore", { clear = true }),
      callback = function(opts)
        local bufnr = opts.buf
        -- Only restore cursor if this buffer was opened by telescope
        local was_opened_by_telescope = pcall(vim.api.nvim_buf_get_var, bufnr, "telescope_opened")
        if was_opened_by_telescope then
          local ok, pos = pcall(vim.api.nvim_buf_get_var, bufnr, "telescope_cursor_pos")
          if ok and pos then
            vim.api.nvim_win_set_cursor(0, { pos.line, pos.col })
            vim.cmd("normal! zz")
            -- clean up the variable after using it
            vim.api.nvim_buf_del_var(bufnr, "telescope_cursor_pos")
            vim.api.nvim_buf_del_var(bufnr, "telescope_opened")
          end
        end
      end,
    })
  else
    -- If not dealing with files, use default action
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

------------------------------------------------------------------------------
--- Creates a multi-grep picker that allows searching with both pattern and file glob
--- Usage: pattern  glob (note: two spaces between pattern and glob)
---
--- @param opts table Configuration options for the picker
------------------------------------------------------------------------------
function M.pickers.multi_grep(opts)
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

---@type table<string, table>
M.themes = {
  wide_preview = {
    theme = "wide_preview",
    layout_config = {
      preview_width = 0.6,
      width = 0.7,
      height = 0.85,
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
      preview_cutoff = 1,
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
------------------------------------------------------------------------------
--- Wraps a telescope picker with a specific layout theme
---
---@param picker string The telescope picker to run
---@param layout? string The theme layout to use (must be a key in themes table)
---@param opts? table Optional settings to override theme defaults
---@return function The wrapped picker function with applied theme and options
------------------------------------------------------------------------------
function M.wrap(picker, layout, opts)
  opts = opts or {}
  layout = layout or "wide_preview"
  local buf = vim.api.nvim_get_current_buf() or 0
  local root_pattern = opts.root_pattern or { ".git", "lua", ".env", "package.json" }
  if not opts.cwd and opts.root ~= false and opts.cwd_only ~= true then
    opts.cwd = Utils.root({ buf = buf, patterns = root_pattern })
  end
  opts = vim.tbl_deep_extend("force", M.themes[layout], opts or {})
  return function()
    if M.pickers[picker] then
      M.pickers[picker](opts)
    else
      require("telescope.builtin")[picker](opts)
    end
  end
end

return M
