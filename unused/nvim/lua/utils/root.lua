---@class utils.root
local M = setmetatable({}, {
  ---@param buf? number
  __call = function(m, buf)
    return m.get(buf)
  end,
})

local uv = vim.uv or vim.loop
-- Default root patterns
M.root_patterns = {
  ".git",
  "lua",
  "stylua.toml",
  "pyproject.toml",
  "pyproject.toml",
  "uv.lock",
  "requirements.txt",
  "pyrightconfig.json",
  "biome.json",
  "package.json",
  "biome.jsonc",
}
M.ignore_lsp = { "copilot" }

-- Cache for root directories by buffer
---@type table<number, string>
M.cache = {}

-- Cache for git ancestors by path
---@type table<string, string|false>
M.git_cache = {}

-- Get the real path of a file/directory
---@param path string # the path to resolve
---@return string|nil # the resolved path or nil if it cannot be resolved
function M.get_real_path(path)
  if not path or path == "" then return nil end
  path = uv.fs_realpath(path) or path
  return Utils.norm(path)
end

-- Get current working directory
function M.cwd()
  return M.get_real_path(vim.uv.cwd()) or vim.uv.cwd()
end

---------------------------------------------------------------
-- Get the path of a buffer
---@param buf number # the buffer number
---@return string|nil # the path of the buffer or nil if it cannot be determined
---------------------------------------------------------------
function M.get_buffer_path(buf)
  local path = Utils.get_filepath(assert(buf))
  return path ~= "" and M.get_real_path(path) or nil
end

-----------------------------------------------------
-- get root markers with specific field in files
---@param root_files string[]
---@param new_files string[]
---@param field string
---@param fname string
---@return string[]
-----------------------------------------------------
function M.markers_with_field(root_files, new_files, field, fname)
  local path = vim.fn.fnamemodify(fname, ":h")
  local found = vim.fs.find(new_files, { path = path, upward = true })

  for _, f in ipairs(found or {}) do
    -- Match the given `field`.
    for line in io.lines(f) do
      if line:find(field) then
        root_files[#root_files + 1] = vim.fs.basename(f)
        break
      end
    end
  end

  return root_files
end

----------------------------------------------------------------
-- Find the nearest git ancestor directory
---@param path? string # the path to start searching from
---@param buf? number # the buffer number to get the path from
---@return string? # the path to the git root or nil if not found
-----------------------------------------------------------------
function M.find_git_ancestor(path, buf)
  if not path then
    if buf then
      path = M.get_buffer_path(buf)
    else
      path = M.cwd()
    end
  end
  if not path or path == "" then return nil end
  path = M.get_real_path(path)
  if not path then return nil end

  if M.git_cache[path] ~= nil then return M.git_cache[path] or nil end

  local git_files = vim.fs.find(".git", {
    path = path,
    upward = true,
    type = "directory",
  })
  local git_root
  if git_files and git_files[1] then
    git_root = vim.fs.dirname(git_files[1])
    git_root = git_root and M.get_real_path(git_root)
  end

  M.git_cache[path] = git_root or false

  return git_root
end

---------------------------------------------------------------
-- Find project root based on patterns
---@param buf number the buffer number
---@param patterns string[]|string patterns to search for
---------------------------------------------------------------
function M.find_pattern_root(buf, patterns)
  patterns = Utils.ensure_list(patterns) ---@type string[]
  buf = Utils.ensure_buf(buf)
  local path = M.get_buffer_path(buf) or vim.uv.cwd()
  if not path or path == "" then return nil end

  ---@type fun(name: string, pattern: string): boolean
  local function matches_pattern(name, pattern)
    if pattern == name then return true end

    if pattern:find("*") then
      local escaped = vim.pesc(pattern):gsub("%%*", ".*")
      return name:match("^" .. escaped .. "$") ~= nil
    end
    return false
  end

  local pattern = vim.fs.find(function(name)
    for _, p in ipairs(patterns) do
      if matches_pattern(name, p) then return true end
    end
    return false
  end, {
    path = path,
    upward = true,
    stop = uv.os_homedir(),
  })[1]
  return pattern and vim.fs.dirname(pattern) or nil
end

---------------------------------------------------------------
-- Get root directory based on LSP
---@param buf number the buffer number
---------------------------------------------------------------
function M.find_lsp_root(buf)
  local bufpath = M.get_buffer_path(buf)
  if not bufpath then return nil end

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
        if path then roots[#roots + 1] = M.get_real_path(path) end
      end
    end
    if client.config.root_dir then roots[#roots + 1] = M.get_real_path(client.config.root_dir) end
  end

  -- Filter out roots that don't contain the buffer path
  return vim.tbl_filter(function(path)
    return path and bufpath:find(path, 1, true) == 1
  end, roots)[1]
end

---------------------------------------------------------------
-- Add patterns to the root patterns
---@param patterns string|string[] # patterns to add
---------------------------------------------------------------
function M.add_patterns(patterns)
  patterns = Utils.ensure_list(patterns) ---@type string[]
  for _, pattern in ipairs(patterns) do
    if not vim.tbl_contains(M.root_patterns, pattern) then table.insert(M.root_patterns, pattern) end
  end
end

---@class root.opts
---@field prefer_git boolean # prefer git root if available
---@field skip_cache boolean # skip cache lookup
---@field patterns tabl

---------------------------------------------------------------
-- Get the project root directory
---@param buf? number
---@param opts? root.opts
---------------------------------------------------------------
function M.get(buf, opts)
  opts = opts or {}
  buf = Utils.ensure_buf(buf)
  if opts.patterns then M.add_patterns(opts.patterns) end

  local root
  if not opts.skip_cache and M.cache[buf] then return M.cache[buf] end

  if opts.prefer_git then root = M.find_git_ancestor(nil, buf) end

  -- Try LSP root first (higher priority)
  if not root then root = M.find_lsp_root(buf) end

  if not root and not opts.prefer_git then root = M.find_git_ancestor(nil, buf) end

  if not root then root = M.find_pattern_root(buf, M.root_patterns) end

  if not root then root = M.cwd() end

  if not opts.skip_cache and M.cache[buf] then M.cache[buf] = root end
  return root
end

function M.clear_cache()
  M.cache = {}
  M.git_cache = {}
end

function M.clear_buf_cache(buf)
  if not buf or not M.cache[buf] then return end
  M.cache[buf] = nil
  local path = M.get_buffer_path(buf)
  if path and M.git_cache[path] then M.git_cache[path] = nil end
end

---------------------------------------------------------------
-- Setup autocmds to clear root cache
---------------------------------------------------------------
function M.setup()
  Utils.autocmd.autocmd_augroup("utils_root_cache", {
    {
      events = { "LspAttach", "LspDetach", "BufWritePost", "BufEnter" },
      callback = function(event)
        if event and event.buf then M.clear_buf_cache(event.buf) end
      end,
    },
    {
      events = { "DirChanged" },
      callback = function()
        M.clear_cache()
      end,
    },
    {
      events = { "BufWritePost" },
      pattern = { "*.gitignore", "*.gitconfig", "*.gitmodules", ".git/index" },
      callback = function()
        M.git_cache = {}
      end,
    },
  })
end

return M
