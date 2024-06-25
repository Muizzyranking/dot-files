local M = {}

-- Store the terminal buffer and window
M.term_buf = nil
M.term_win = nil

--------------------------------------------------
-- Create a floating window
---@return number
--------------------------------------------------
local function create_float_window()
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  local opts = {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    focusable = true, -- Ensure the window can receive focus
  }

  return vim.api.nvim_open_win(0, true, opts)
end

--------------------------------------------------
-- Toggle a floating terminal window
---@param cmd string|nil
--------------------------------------------------
function M.toggle_float_terminal(cmd)
  if M.term_win and vim.api.nvim_win_is_valid(M.term_win) then
    -- Terminal window exists, hide it
    vim.api.nvim_win_hide(M.term_win)
    M.term_win = nil
  else
    if M.term_buf and vim.api.nvim_buf_is_valid(M.term_buf) then
      -- Terminal buffer exists, show it in a new window
      M.term_win = create_float_window()
      vim.api.nvim_win_set_buf(M.term_win, M.term_buf)
      vim.api.nvim_win_set_option(M.term_win, "winblend", 0)

      -- If a command is provided, send it to the existing terminal
      if cmd then
        vim.api.nvim_chan_send(vim.bo[M.term_buf].channel, cmd .. "\n")
      end
    else
      -- Create new terminal buffer and window
      M.term_buf = vim.api.nvim_create_buf(false, true)
      M.term_win = create_float_window()
      vim.api.nvim_win_set_buf(M.term_win, M.term_buf)

      -- Open terminal with default shell
      vim.fn.termopen(vim.o.shell, {
        on_exit = function()
          M.term_buf = nil
          M.term_win = nil
        end,
      })
      -- If a command is provided, send it to the new terminal
      if cmd then
        vim.api.nvim_chan_send(vim.bo[M.term_buf].channel, cmd .. "\n")
      end
    end
    vim.bo[M.term_buf].filetype = "myterm"
    -- Enter insert mode
    vim.api.nvim_buf_set_keymap(
      M.term_buf,
      "n",
      "q",
      ':lua require("utils.toggleterm").toggle_float_terminal()<CR>',
      { noremap = true, silent = true }
    )

    vim.cmd("startinsert")
  end
end

return M
