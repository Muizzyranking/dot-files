--------------------------------------------------
-- Function to create a floating window and run a command
---@param cmd string[]
---@param opts? table
-----------------------------------------------
local float_cmd = function(cmd, opts)
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
local function lazygit(args)
  local opts = {
    cmd = { "lazygit", unpack(args or {}) },
    filetype = "lazygit",
  }
  float_cmd(opts.cmd, opts)
end

return lazygit
