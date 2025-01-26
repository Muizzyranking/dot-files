---@class utils.terminal
local M = setmetatable({}, {
  __call = function(m, cmd)
    return m.float_term(cmd)
  end,
})

---------------------------------------------------------------
--- Calculate dimensions for a floating window
---@param opts table Options for window dimensions
---@return number, number, number, number - Width, height, row, and column of the window
---------------------------------------------------------------
function M.get_dimensions(opts)
  local width = math.floor(vim.o.columns * (opts.width or 0.9))
  local height = math.floor(vim.o.lines * (opts.height or 0.8))
  local row = math.floor((vim.o.lines - height) / 2) - (opts.row_offset or 1)
  local col = math.floor((vim.o.columns - width) / 2)
  return width, height, row, col
end

---------------------------------------------------------------
--- Create a floating window
---@param buf number Buffer to display in the floating window
---@param opts table Options for the floating window
---@return number Window handle
---------------------------------------------------------------
function M.create_float_window(buf, opts)
  local width, height, row, col = M.get_dimensions(opts)
  local float_opts = {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border or "rounded",
    focusable = true,
  }
  local win = vim.api.nvim_open_win(buf, true, float_opts)
  vim.api.nvim_win_set_option(win, "winblend", opts.winblend or 0)
  return win
end

---------------------------------------------------------------
--- Update the size of an existing window
---@param win number Window handle
---@param opts table Options for window dimensions
---------------------------------------------------------------
function M.update_window_size(win, opts)
  if vim.api.nvim_win_is_valid(win) then
    local width, height, row, col = M.get_dimensions(opts)
    vim.api.nvim_win_set_config(win, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
    })
  end
end
---------------------------------------------------------------
--- Creates a floating terminal window
---@param cmd string|table The command to execute in the terminal
---@param opts table|nil Options for creating the floating window
---@return number, number The buffer and window handles
---------------------------------------------------------------
function M.create_float_term(cmd, opts)
  -- Set default options if not provided
  opts = opts or {}
  opts.filetype = opts.filetype or "float_term"

  -- Create a new, unnamed buffer for the terminal
  local buf = vim.api.nvim_create_buf(false, true)

  -- Create a floating window for the buffer
  local win = M.create_float_window(buf, opts)

  -- Set up autocommands to update window size when Vim is resized
  vim.api.nvim_create_autocmd({ "VimResized" }, {
    pattern = { opts.filetype },
    group = vim.api.nvim_create_augroup("float-win-resize" .. buf, { clear = true }),
    callback = function()
      M.update_window_size(win, opts)
    end,
  })

  -- Open the terminal with the provided command
  vim.fn.termopen(cmd, {
    on_exit = function()
      -- Close window and buffer after execution if auto_close is enabled
      if opts.auto_close then
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
      vim.api.nvim_input("<C-\\><C-n>")
    end,
  })

  -- Set buffer filetype
  vim.bo[buf].filetype = opts.filetype

  -- Set up keymaps
  local keymap_opts = { buffer = buf, nowait = true }
  local function map(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, keymap_opts)
  end
  if opts.no_esc then
    map({ "t", "n" }, "<esc>", "<esc>")
  end
  map({ "n", "t" }, "<c-h>", "<c-h>")
  map({ "n", "t" }, "<c-j>", "<c-j>")
  map({ "n", "t" }, "<c-k>", "<c-k>")
  map({ "n", "t" }, "<c-l>", "<c-l>")

  map("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
  vim.cmd("startinsert")
  return buf, win
end

--- Handle to the terminal window
M.term_win = nil

--- Handle to the terminal buffer
M.term_buf = nil

-- Configure options for the floating window
local opts = {
  width = 0.9,
  height = 0.8,
  filetype = "term",
}
---------------------------------------------------------------
--- Creates or toggles a floating terminal
---@param cmd string|nil Optional command to execute in the terminal
---------------------------------------------------------------
function M.float_term(cmd)
  if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    -- Hide the terminal window if it's already visible
    vim.api.nvim_win_hide(M.term_win)
    M.term_win = nil
  else
    if M.term_buf and vim.api.nvim_buf_is_valid(M.term_buf) then
      -- Reuse existing buffer if valid
      M.term_win = M.create_float_window(M.term_buf, opts)
      vim.cmd("startinsert")
      if cmd then
        vim.schedule(function()
          vim.api.nvim_chan_send(vim.bo[M.term_buf].channel, cmd .. "\n")
        end)
      end
    else
      -- Create a new terminal if no valid buffer exists
      M.term_buf, M.term_win = M.create_float_term(vim.o.shell, opts)
      if cmd then
        vim.defer_fn(function()
          vim.api.nvim_chan_send(vim.bo[M.term_buf].channel, cmd .. "\n")
        end, 100)
      end
    end
  end
end

----------------------------------------------------
-- lualine component to show when in terminal buffer
----------------------------------------------------
M.lualine = {
  sections = {
    lualine_a = {
      function()
        return " Terminal"
      end,
    },
  },
  filetypes = { opts.filetype },
}

return M
