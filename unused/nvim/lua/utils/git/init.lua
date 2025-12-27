---@class utils.git
---@field conflict utils.git.conflict
local M = {}

setmetatable(M, {
  __index = function(t, k)
    t[k] = require("utils.git." .. k)
    return t[k]
  end,
})

-- execute git command
---@param args string[] list of git arguments
---@param cwd? string current working directory
---@return string?, number? output of the git command
function M.exec(args, cwd)
  local cmd = { "git", "--no-pager", "-c", "color.status=false", "-c", "core.quotepath=false" }
  if cwd then
    table.insert(cmd, "-C")
    table.insert(cmd, cwd)
  end
  vim.list_extend(cmd, args)

  local success, res = Utils.run_command(cmd, { trim = false })
  if not success then return nil end
  return res:gsub("%s+$", "")
end

function M.is_in_git_repo(notify)
  notify = notify or false
  local success, output = Utils.run_command({ "git", "rev-parse", "--is-inside-work-tree" }, {
    trim = true,
    callback = function(output, success, _)
      if notify and not success then Utils.notify.error("Failed to check git repository: " .. output) end
    end,
  })
  return success and output:match("true") ~= nil
end

---@return string|nil
function M.get_git_root()
  return M.exec({ "rev-parse", "--show-toplevel" })
end

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", {}, opts or {})
  require("utils.git.conflict").setup(opts)
end

return M
