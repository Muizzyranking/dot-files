---@class utils.root
local M = setmetatable({}, {
  ---@param buf? number
  __call = function(m, buf)
    return m.get(buf)
  end,
})

-- Default root patterns
M.root_patterns = { ".git" }
M.ignore_lsp = { "copilot" }
M.filetype_patterns = {}

-- Cache for root directories by buffer
---@type table<number, string>
M.cache = {}

-- Get the real path of a file/directory
function M.get_real_path(path)
  if not path or path == "" then
    return nil
  end
  path = vim.uv.fs_realpath(path) or path
  return Utils.norm(path)
end

-- Get current working directory
function M.cwd()
  return M.get_real_path(vim.uv.cwd()) or ""
end

---------------------------------------------------------------
-- Get the path of a buffer
---@param buf number the buffer number
---------------------------------------------------------------
function M.get_buffer_path(buf)
  local path = vim.api.nvim_buf_get_name(assert(buf))
  return path ~= "" and M.get_real_path(path) or nil
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
    type = "directory",
    stop = vim.uv.os_homedir(),
  })[1]
  return pattern and vim.fs.dirname(pattern) or nil
end

-- Get root directory based on LSP
---------------------------------------------------------------
---@param buf number the buffer number
---------------------------------------------------------------
function M.find_lsp_root(buf)
  local bufpath = M.get_buffer_path(buf)
  if not bufpath then
    return nil
  end

  local roots = {} ---@type string[]
  local clients = Utils.lsp.get_clients({
    bufnr = buf,
    filter = function(client)
      return not vim.tbl_contains(M.ignore_lsp, client.name)
    end,
  })

  for _, client in pairs(clients) do
    if client.config.workspace_folders then
      for _, ws in pairs(client.config.workspace_folders) do
        local path = vim.uri_to_fname(ws.uri)
        if path then
          roots[#roots + 1] = M.get_real_path(path)
        end
      end
    end
    if client.config.root_dir then
      roots[#roots + 1] = M.get_real_path(client.config.root_dir)
    end
  end

  -- Filter out roots that don't contain the buffer path
  return vim.tbl_filter(function(path)
    return path and bufpath:find(path, 1, true) == 1
  end, roots)[1]
end

---------------------------------------------------------------
-- Add patterns to the root patterns
---@param patterns string|string[] # patterns to add
---@param filetype? string
---------------------------------------------------------------
function M.add_patterns(patterns, filetype)
  patterns = type(patterns) == "string" and { patterns } or patterns
  if filetype and filetype ~= "*" then
    M.filetype_patterns[filetype] = M.filetype_patterns[filetype] or {}
    for _, pattern in ipairs(patterns) do
      if not vim.tbl_contains(M.filetype_patterns[filetype], pattern) then
        table.insert(M.filetype_patterns[filetype], pattern)
      end
    end
  else
    for _, pattern in ipairs(patterns) do
      if not vim.tbl_contains(M.root_patterns, pattern) then
        table.insert(M.root_patterns, pattern)
      end
    end
  end
end

---@param filetype string
---@return string[] # combined pattern
function M.get_ft_pattern(filetype)
  local pattern = vim.deepcopy(M.root_patterns)
  if filetype and M.filetype_patterns[filetype] then
    for _, p in ipairs(M.filetype_patterns[filetype]) do
      if not vim.tbl_contains(pattern, p) then
        table.insert(pattern, p)
      end
    end
  end
  return pattern
end

---------------------------------------------------------------
-- Get the project root directory
---@param buf? number
---------------------------------------------------------------
function M.get(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf

  if M.cache[buf] then
    return M.cache[buf]
  end

  -- Try LSP root first (higher priority)
  local root = M.find_lsp_root(buf)
  if root then
    M.cache[buf] = root
    return root
  end

  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  local patterns = M.get_ft_pattern(filetype)
  root = M.find_pattern_root(buf, patterns)
  if root then
    M.cache[buf] = root
    return root
  end

  -- Fallback to CWD
  root = M.cwd()
  M.cache[buf] = root
  return root
end

---------------------------------------------------------------
-- Setup autocmds to clear root cache
---------------------------------------------------------------
function M.setup()
  vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("utils_root_cache", { clear = true }),
    callback = function(event)
      M.cache[event.buf] = nil
    end,
  })
end

return M
