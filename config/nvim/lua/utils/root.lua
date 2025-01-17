---@class utils.root
local M = {}

-- Default root patterns
M.root_patterns = { ".git", "lua" }

-- Get the real path of a file/directory
function M.get_real_path(path)
  if not path or path == "" then
    return nil
  end
  path = vim.uv.fs_realpath(path) or path
  return Utils.norm(path)
end

-- Get current working directory
function M.get_cwd()
  return M.get_real_path(vim.uv.cwd())
end

---------------------------------------------------------------
-- Get the path of a buffer
---@param buf number the buffer number
---------------------------------------------------------------
function M.get_buffer_path(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    return nil
  end
  return M.get_real_path(path)
end

---------------------------------------------------------------
-- Find project root based on patterns
---@param buf number the buffer number
---@param patterns string[]|string patterns to search for
---------------------------------------------------------------
function M.find_pattern_root(buf, patterns)
  patterns = type(patterns) == "string" and { patterns } or patterns ---@type string[]

  local path = M.get_buffer_path(buf) or vim.uv.cwd()
  local pattern = vim.fs.find(function(name)
    for _, p in ipairs(patterns) do
      if name == p or (p:sub(1, 1) == "*" and name:find(vim.pesc(p:sub(2)) .. "$")) then
        return true
      end
    end
    return false
  end, {
    path = path,
    upward = true,
  })[1]

  return pattern and vim.fs.dirname(pattern) or nil
end

---------------------------------------------------------------
-- Get root directory based on LSP
---@param buf number the buffer number
---------------------------------------------------------------
function M.find_lsp_root(buf)
  local clients = Utils.lsp.get_clients({ bufnr = buf })

  for _, client in pairs(clients) do
    if client.config.workspace_folders then
      for _, ws in pairs(client.config.workspace_folders) do
        local path = vim.uri_to_fname(ws.uri)
        if path then
          return M.get_real_path(path)
        end
      end
    end
    if client.config.root_dir then
      return M.get_real_path(client.config.root_dir)
    end
  end

  return nil
end

---------------------------------------------------------------
-- Get the project root directory
---@param opts? {patterns?: string|string[], buf?: number}
---------------------------------------------------------------
function M.get(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()

  local root = M.find_lsp_root(buf)
  if root then
    return root
  end

  local patterns = opts.patterns or M.root_patterns
  root = M.find_pattern_root(buf, patterns)
  if root then
    return root
  end

  return M.get_cwd()
end

return M
