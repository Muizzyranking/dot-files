local M = {}

function M.detect_and_activate_venv(root)
  if not root or os.getenv("VIRTUAL_ENV") then
    return false
  end

  local venv_names = { "venv", ".venv" }
  for _, venv in ipairs(venv_names) do
    local venv_path = root .. "/" .. venv
    local activate_path = venv_path .. "/bin/activate"
    local python_path = venv_path .. "/bin/python"

    if vim.fn.filereadable(activate_path) == 1 and vim.fn.isdirectory(venv_path) == 1 then
      vim.env.VIRTUAL_ENV = venv_path
      if not vim.env.PATH:find(venv_path .. "/bin", 1, true) then
        vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH
      end
      vim.g.python3_host_prog = python_path

      return { venv_path = venv_path, python_path = python_path }
    end
  end

  return false
end

return M
