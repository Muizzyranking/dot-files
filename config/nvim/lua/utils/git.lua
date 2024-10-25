local M = {}
local utils = require("utils")
local notify = require("utils.notify")
local terminal = require("utils.terminal")

---------------------------------------------------------------
--- Open lazygit in a floating terminal
---@param args string[]|nil Additional arguments for lazygit
---------------------------------------------------------------
function M.lazygit(args)
  if not utils.is_in_git_repo then
    notify.warn("Not in a git repository, must be in a git repo", { title = "LazyGit" })
    return
  end
  if not utils.is_executable("lazygit") then
    notify.error("LazyGit is not installed", { title = "LazyGit" })
    return
  end
  local cmd = { "lazygit", unpack(args or {}) }
  local opts = {
    width = 0.95,
    height = 0.9,
    filetype = "lazygit",
    auto_close = true,
    no_esc = true,
  }
  terminal.create_float_term(cmd, opts)
end

---------------------------------------------------------------
--- Lualine configuration for lazygit
---@type table
---------------------------------------------------------------
M.lualine = {
  sections = {
    lualine_a = {
      function()
        return " Lazygit"
      end,
    },
    lualine_b = {
      {
        "branch",
        color = { gui = "italic" },
      },
    },
  },
  filetypes = { "lazygit" },
}

---------------------------------------------------------------
-- Display git blame information for the current line in a floating window.
---@param opts table: Optional parameters for customizing the floating window.
---@return any The result of lazy.util.float_cmd
---------------------------------------------------------------
function M.blame_line(opts)
  -- Merge default options with provided options
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
  local root = utils.find_root_directory(0, { ".git" })[1] or "."

  -- Construct git command
  local cmd = { "git", "-C", root, "log", "-n", opts.count, "-u", "-L", line .. ",+1:" .. file }

  -- Execute command in a floating window
  return require("lazy.util").float_cmd(cmd, opts)
end

return M
