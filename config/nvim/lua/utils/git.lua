local M = {}

--------------------------------------------------
-- Function to create a floating window and run a command
---@param cmd string[]
---@param opts? table
-----------------------------------------------
local create_win = function(cmd, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.95)
  local height = math.floor(vim.o.lines * 0.9)
  local col = math.floor((vim.o.columns - width) / 2)

  local float_opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = 1,
    col = col,
    border = "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, float_opts)
  vim.api.nvim_win_set_option(win, "winblend", 0)
  vim.cmd("startinsert")

  vim.fn.termopen(cmd, {
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end,
  })

  if opts.filetype then
    vim.bo[buf].filetype = opts.filetype
  end

  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>bd!<CR>", { noremap = true, silent = true })
end

--------------------------------------------------
-- Open lazygit in a floating window
---@param args string[]|nil
--------------------------------------------------
function M.lazygit(args)
  local opts = {
    cmd = { "lazygit", unpack(args or {}) },
    filetype = "lazygit",
  }
  create_win(opts.cmd, opts)
end

-------------------------------------
-- Create a floating window with specified options.
---@param opts table: Options for creating the floating window.
-------------------------------------
function M.float(opts)
  return require("lazy.view.float")(opts)
end

-------------------------------------
-- Execute a command in a floating terminal window with optional file type.
---@param cmd string[]: The command to be executed.
---@param opts table: Optional parameters for customizing the floating window.
-------------------------------------
function M.float_cmd(cmd, opts)
  opts = opts or {}
  local float = M.float(opts)
  if opts.filetype then
    vim.bo[float.buf].filetype = opts.filetype
  end
  local Process = require("lazy.manage.process")
  local lines = Process.exec(cmd, { cwd = opts.cwd })
  vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, lines)
  vim.bo[float.buf].modifiable = false
  return float
end

-------------------------------------
-- Display git blame information for the current line in a floating window.
---@param opts table: Optional parameters for customizing the floating window.
-------------------------------------
function M.blame_line(opts)
  opts = vim.tbl_deep_extend("force", {
    count = 3,
    filetype = "git",
    size = {
      width = 0.6,
      height = 0.6,
    },
    border = "rounded",
  }, opts or {})
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local file = vim.api.nvim_buf_get_name(0)
  local cmd = { "git", "log", "-n", opts.count, "-u", "-L", line .. ",+1:" .. file }
  return M.float_cmd(cmd, opts)
end

return M
