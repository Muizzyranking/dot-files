---@class utils.python
local M = {}

--[[
changes a python string to an f-string when {{ is typed.
If it is already an f-string, it insert { normally.
When not in a string, it auto-closes braces.

example:
var = "value { |" adding { -> var = f"value { | }"
--]]

---@class StringInfo
---@field in_string boolean
---@field string_start integer?
---@field string_quote string?
---@field is_fstring boolean
---@field prefix_start integer?

---@param line string
---@param col integer
---@return StringInfo
local function get_string_info(line, col)
  local result = {
    in_string = false,
    string_start = nil,
    string_quote = nil,
    is_fstring = false,
    prefix_start = nil,
  }
  local i = 1
  while i <= col do
    local char = line:sub(i, i)
    if result.in_string then
      if char == "\\" then
        i = i + 2
      elseif result.string_quote and line:sub(i, i + #result.string_quote - 1) == result.string_quote then
        local quote_len = #result.string_quote
        result.in_string = false
        result.string_start = nil
        result.string_quote = nil
        result.is_fstring = false
        result.prefix_start = nil
        i = i + quote_len
      else
        i = i + 1
      end
    elseif char == '"' or char == "'" then
      local triple = line:sub(i, i + 2)
      local quote = (triple == '"""' or triple == "'''") and triple or char
      local ps = i - 1
      while ps > 0 and line:sub(ps, ps):match("%a") do
        ps = ps - 1
      end
      ps = ps + 1
      local prefix = line:sub(ps, i - 1):lower()
      result.in_string = true
      result.string_quote = quote
      result.string_start = i
      result.is_fstring = prefix:find("f") ~= nil
      result.prefix_start = ps
      i = i + #quote
    else
      i = i + 1
    end
  end
  return result
end

function M.handle_brace()
  local win = vim.api.nvim_get_current_win()
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  row = row - 1
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""

  local function insert(text, new_col)
    vim.api.nvim_buf_set_text(0, row, col, row, col, { text })
    vim.api.nvim_win_set_cursor(win, { row + 1, new_col })
  end

  -- outside string: autopair {}
  local info = get_string_info(line, col)
  if not info.in_string then
    insert("{}", col + 1)
    return
  end

  -- inside f-string: just insert {, no autopair needed
  if info.is_fstring then
    insert("{", col + 1)
    return
  end

  -- inside regular string, first {: just insert it
  local prev_char = col > 0 and line:sub(col, col) or ""
  if prev_char ~= "{" then
    insert("{", col + 1)
    return
  end

  -- inside regular string, second {: convert to f-string and make {}
  local f_insert_pos = (info.prefix_start or info.string_start) - 1
  vim.api.nvim_buf_set_text(0, row, f_insert_pos, row, f_insert_pos, { "f" })

  -- col shifts by 1 after inserting "f"
  local brace_start = col
  vim.api.nvim_buf_set_text(0, row, brace_start, row, brace_start + 1, { "{}" })
  vim.api.nvim_win_set_cursor(win, { row + 1, brace_start + 1 })
end

local active_venv = nil
local venv_cache = {}

function M.detect_venv(root)
  if not root then
    return nil
  end

  -- Check cache first, but validate it's still valid
  if venv_cache[root] then
    local cached = venv_cache[root]
    if cached and vim.fn.isdirectory(cached.venv_path) == 1 and Utils.fn.is_executable(cached.python_path) then
      return cached
    end
    venv_cache[root] = nil
  end

  -- Don't override existing VIRTUAL_ENV
  local current_venv = vim.env.VIRTUAL_ENV
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
    if Utils.fn.is_executable(python_path) then
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

function M.venv_activate(venv_info)
  if not venv_info then
    return false
  end

  vim.env.VIRTUAL_ENV = venv_info.venv_path
  vim.env.PATH = venv_info.venv_path .. "/bin:" .. vim.env.PATH
  vim.g.python3_host_prog = venv_info.python_path

  return true
end

function M.detect_and_activate_venv(root)
  local venv_info = M.detect_venv(root)
  if venv_info then
    M.venv_activate(venv_info)
  end
  return venv_info
end

function M.activate_venv(buf)
  buf = Utils.fn.ensure_buf(buf)

  if vim.bo[buf].filetype ~= "python" then
    return
  end
  local root = Utils.root(buf)
  local venv_info = M.detect_venv(root)
  if not venv_info then
    return
  end

  if active_venv == venv_info.venv_path then
    return
  end

  if M.venv_activate(venv_info) then
    active_venv = venv_info.venv_path
    Utils.notify.info("venv: " .. venv_info.venv_path)
  end
end

return M
