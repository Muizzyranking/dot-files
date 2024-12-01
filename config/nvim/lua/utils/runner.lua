---@class utils.runner
local M = {}

---@type table
local opts = {
  width = 0.8,
  height = 0.6,
  row_offset = 2,
  border = "rounded",
  auto_close = false,
  filetype = "CodeRunner",
}

-- Store the last command and its output
---@type string|nil
M.last_command = nil
---@type string[]|nil
M.last_output = nil

---------------------------------------------------------------
-- Get the directory of a file
---@param file string
---@return string
---------------------------------------------------------------
local function get_file_directory(file)
  return vim.fn.fnamemodify(file, ":h")
end

---------------------------------------------------------------
-- Get the file name without extension
---@param file string
---@return string
---------------------------------------------------------------
local function get_file_name_without_extension(file)
  return vim.fn.fnamemodify(file, ":t:r")
end

---------------------------------------------------------------
-- Create a hidden output directory for compiled languages
---@param dir string
---@return string|nil
---------------------------------------------------------------
local function create_hidden_output_dir(dir)
  local output_dir = dir .. "/.coderunner"
  if vim.fn.isdirectory(output_dir) == 0 then
    vim.fn.mkdir(output_dir, "p")
  end
  return output_dir
end

---------------------------------------------------------------
-- Find the main entry point file
---@param dir string
---@param patterns string[]
---@return string|nil
---------------------------------------------------------------
local function find_entry_point(dir, patterns)
  for _, pattern in ipairs(patterns) do
    local files = vim.fn.glob(dir .. "/" .. pattern, false, true)
    if #files > 0 then
      return files[1]
    end
  end
  return nil
end

---------------------------------------------------------------
-- Language-specific configurations
---@type table<string, table>
---------------------------------------------------------------
local lang_configs = {
  python = {
    compiled = false,
    ---@param file string
    run = function(file)
      return string.format("python %s", file)
    end,
    ---@param dir string
    run_program = function(dir)
      local entry_point = find_entry_point(dir, { "main.py", "app.py" })
      if entry_point then
        return string.format("python %s", entry_point)
      else
        return string.format("python -m %s", vim.fn.fnamemodify(dir, ":t"))
      end
    end,
    runner = "python",
  },
  c = {
    compiled = true,
    run = function(dir)
      return string.format("cd %q && ./bin", dir)
    end,
    compile = function(file, output_dir)
      local name = get_file_name_without_extension(file)
      local cmd
      cmd = string.format("gcc %q -o %s/bin", file, output_dir, name)
      return cmd
    end,
    compile_program = function(dir, output_dir)
      local cmd = string.format("gcc %s/*.c -o %s/bin", dir, output_dir)
      return cmd
    end,
    runner = "gcc",
  },
}

---------------------------------------------------------------
-- Get the current file path
---@return string
---------------------------------------------------------------
local function get_current_file()
  return vim.fn.expand("%:p")
end

---------------------------------------------------------------
-- Run a command in a floating terminal
---@param cmd string
---------------------------------------------------------------
local function run_in_float_term(cmd)
  M.last_command = cmd
  local buf, _ = Utils.terminal.create_float_term(cmd, opts)

  -- Capture the output
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function(_, _, _, _, _, _)
      M.last_output = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    end,
  })
end

---------------------------------------------------------------
-- Run the current file
---@param lang string
---@param with_args boolean
---------------------------------------------------------------
function M.run_file(lang, with_args)
  local file = get_current_file()
  local config = lang_configs[lang]
  local cmd
  local args = ""

  if not config then
    print("Unsupported language: " .. lang)
    return
  end

  if with_args then
    args = vim.fn.input("Enter arguments: ")
  end

  local dir = get_file_directory(file)
  local output_dir = config.compiled and create_hidden_output_dir(dir) or nil

  if not output_dir and config.compiled then
    return
  end

  if config.compile then
    -- Compile the file and capture the result
    local compile_cmd = config.compile(file, output_dir)
    local compile_output = vim.fn.system(compile_cmd)

    if vim.v.shell_error ~= 0 then
      Utils.notify.error("Compilation failed:\n" .. compile_output, { title = "CodeRunner" })
      return
    end

    cmd = config.run(output_dir) .. " " .. args
  else
    cmd = config.run(file) .. " " .. args
  end

  run_in_float_term(cmd)
end

---------------------------------------------------------------
-- Run the program in the current directory
---@param lang string
---@param with_args boolean
---------------------------------------------------------------
function M.run_program(lang, with_args)
  local dir = vim.fn.getcwd()
  local config = lang_configs[lang]
  local cmd
  local args = ""

  if not config then
    Utils.notify.error("Unsupported language: " .. lang, { title = "CodeRunner" })
    return
  end

  if with_args then
    args = vim.fn.input("Enter arguments: ")
  end

  local output_dir = config.compiled and create_hidden_output_dir(dir) or nil

  if not output_dir and config.compiled then
    return
  end

  if config.compile then
    -- Compile the file and capture the result
    local compile_cmd = config.compile_program(dir, output_dir)
    local compile_output = vim.fn.system(compile_cmd)

    if vim.v.shell_error ~= 0 then
      Utils.notify.error("Compilation failed:\n" .. compile_output, { title = "CodeRunner" })
      return
    end

    cmd = config.run(output_dir) .. " " .. args
  else
    cmd = config.run_program(dir) .. " " .. args
  end

  run_in_float_term(cmd .. " " .. args)
end

---------------------------------------------------------------
-- Show the last output in a floating window
---------------------------------------------------------------
function M.redo_last_command()
  if M.last_command then
    run_in_float_term(M.last_command)
  else
    print("No previous command to redo")
  end
end

---------------------------------------------------------------
-- Show the last output
---------------------------------------------------------------
function M.show_last_output()
  if M.last_output then
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.last_output)

    local win = Utils.terminal.create_float_window(buf, opts)
    vim.bo[buf].filetype = opts.filetype

    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        local line_count = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_win_set_cursor(win, { line_count, 0 })
      end
    end)

    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
  else
    Utils.notify.info("No previous output to show", { title = "CodeRunner" })
  end
end

---------------------------------------------------------------
-- Set up the CodeRunner for a specific language
---@param lang? string
---------------------------------------------------------------
function M.setup(lang)
  local options = {
    "Run file",
    "Run file(with args)",
    "Run program",
    "Run program (with args)",
    "Redo last command",
    "Show last output",
  }

  lang = lang or vim.bo.filetype
  if not lang_configs[lang] then
    Utils.notify.error("Unsupported language: " .. lang, { title = "CodeRunner" })
    return
  end
  local runner = lang_configs[lang].runner

  if not Utils.is_executable(runner) then
    Utils.notify.error(runner .. " is not installed", { title = "CodeRunner" })
    return
  end

  vim.ui.select(options, { prompt = "Select command:" }, function(choice)
    if choice == "Run file" then
      M.run_file(lang)
    elseif choice == "Run file(with args)" then
      M.run_file(lang, true)
    elseif choice == "Run program" then
      M.run_program(lang)
    elseif choice == "Run program (with args)" then
      M.run_program(lang)
    elseif choice == "Redo last command" then
      M.redo_last_command()
    elseif choice == "Show last output" then
      M.show_last_output()
    end
  end)
end

---------------------------------------------------------------
-- Lualine configuration for CodeRunner
---@type table
---------------------------------------------------------------
M.lualine = {
  sections = {
    lualine_a = {
      function()
        return "  CodeRunner"
      end,
    },
  },
  filetypes = { opts.filetype },
}

return M
