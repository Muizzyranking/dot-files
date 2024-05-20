local M = {}

function M.float(opts)
  return require("lazy.view.float")(opts)
end

---@param cmd string[]
---@param opts? LazyCmdOptions|{filetype?:string}
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
