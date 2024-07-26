---@class MyUtil.terminal
---@overload fun(cmd: string|string[], opts: MyTermOpts): LazyFloat
local M = setmetatable({}, {
  __call = function(m, ...)
    return m.open(...)
  end,
})

---@type table<string,{buf: number, win: number}>
local terminals = {}

---@class MyTermOpts
---@field interactive? boolean
---@field esc_esc? boolean
---@field ctrl_hjkl? boolean
---@field size? {width: number, height: number}

-- Create a floating window
---@param opts MyTermOpts
---@return number
local function create_float_window(opts)
  local width = math.floor(vim.o.columns * (opts.size and opts.size.width or 0.9))
  local height = math.floor(vim.o.lines * (opts.size and opts.size.height or 0.8))
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)
  local win_opts = {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    focusable = true,
  }
  return vim.api.nvim_open_win(0, true, win_opts)
end

-- Toggle terminal visibility
---@param term {buf: number, win: number}
local function toggle_terminal(term)
  if vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_hide(term.win)
  else
    term.win = create_float_window({})
    vim.api.nvim_win_set_buf(term.win, term.buf)
    vim.cmd("startinsert")
  end
end

-- Opens a floating terminal (interactive by default)
---@param cmd? string|string[]
---@param opts? MyTermOpts
function M.open(cmd, opts)
  opts = vim.tbl_deep_extend("force", {
    ft = "myterm",
    size = { width = 0.9, height = 0.8 },
    esc_esc = true,
    ctrl_hjkl = true,
  }, opts or {}, { persistent = true })

  local termkey = vim.inspect({ cmd = cmd or "shell", cwd = opts.cwd, env = opts.env, count = vim.v.count1 })

  if terminals[termkey] and vim.api.nvim_buf_is_valid(terminals[termkey].buf) then
    toggle_terminal(terminals[termkey])
  else
    local buf = vim.api.nvim_create_buf(false, true)
    local win = create_float_window(opts)
    vim.api.nvim_win_set_buf(win, buf)

    terminals[termkey] = { buf = buf, win = win }

    vim.fn.termopen(cmd or vim.o.shell, {
      cwd = opts.cwd,
      env = opts.env,
      on_exit = function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        terminals[termkey] = nil
      end,
    })

    vim.bo[buf].filetype = opts.ft

    if opts.esc_esc == false then
      vim.keymap.set("t", "<esc>", "<esc>", { buffer = buf, nowait = true })
    end
    if opts.ctrl_hjkl == false then
      vim.keymap.set("t", "<c-h>", "<c-h>", { buffer = buf, nowait = true })
      vim.keymap.set("t", "<c-j>", "<c-j>", { buffer = buf, nowait = true })
      vim.keymap.set("t", "<c-k>", "<c-k>", { buffer = buf, nowait = true })
      vim.keymap.set("t", "<c-l>", "<c-l>", { buffer = buf, nowait = true })
    end

    vim.keymap.set("n", "q", function()
      toggle_terminal(terminals[termkey])
    end, { buffer = buf, noremap = true, silent = true })

    vim.api.nvim_create_autocmd("BufEnter", {
      buffer = buf,
      callback = function()
        vim.cmd.startinsert()
      end,
    })

    vim.cmd("startinsert")
  end

  return terminals[termkey]
end

-- Function to toggle the terminal or open with a command
---@param cmd? string|string[]
function M.toggleterm(cmd)
  if cmd then
    M.open(cmd)
  else
    local termkey = vim.inspect({ cmd = "shell", cwd = nil, env = nil, count = vim.v.count1 })
    if terminals[termkey] then
      toggle_terminal(terminals[termkey])
    else
      M.open()
    end
  end
end

return M
