local M = {}

local venv_cache = {}

function M.detect_venv(root)
  if not root then
    return nil
  end

  -- Check cache first, but validate it's still valid
  if venv_cache[root] then
    local cached = venv_cache[root]
    if cached and vim.fn.isdirectory(cached.venv_path) == 1 and Utils.is_executable(cached.python_path) then
      return cached
    else
      venv_cache[root] = nil
    end
  end

  -- Don't override existing VIRTUAL_ENV
  local current_venv = os.getenv("VIRTUAL_ENV")
  if current_venv and vim.startswith(current_venv, root) then
    local result = {
      venv_path = current_venv,
      python_path = current_venv .. "/bin/python",
    }
    venv_cache[root] = result
    return result
  end

  local venv_names = { ".venv", "venv", ".virtualenv", "env" }
  for _, venv_name in ipairs(venv_names) do
    local venv_path = root .. "/" .. venv_name
    local python_path = venv_path .. "/bin/python"

    -- Check if both directory and python executable exist
    if vim.fn.isdirectory(venv_path) == 1 and Utils.is_executable(python_path) then
      local result = {
        venv_path = venv_path,
        python_path = python_path,
      }
      venv_cache[root] = result
      return result
    end
  end

  venv_cache[root] = nil
  return nil
end

function M.activate_venv(venv_info)
  if not venv_info then
    return false
  end

  local venv_path = venv_info.venv_path
  local python_path = venv_info.python_path

  vim.env.VIRTUAL_ENV = venv_path

  local bin_path = venv_path .. "/bin"
  if not vim.env.PATH:find(bin_path, 1, true) then
    vim.env.PATH = bin_path .. ":" .. vim.env.PATH
  end

  vim.g.python3_host_prog = python_path

  return true
end

function M.detect_and_activate_venv(root)
  local venv_info = M.detect_venv(root)
  if venv_info then
    M.activate_venv(venv_info)
    return venv_info
  end
  return nil
end

return M
