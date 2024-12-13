---@class utils.keys
local M = {}

-----------------------------------------------------------
-- Create a new file
-----------------------------------------------------------
function M.new_file()
  local path_and_filename = vim.fn.input("Enter file name: ")
  if path_and_filename == "" then
    return
  end
  local path, filename = vim.fn.fnamemodify(path_and_filename, ":p:h"), vim.fn.fnamemodify(path_and_filename, ":t")
  vim.fn.mkdir(path, "p")
  local full_path = path .. "/" .. filename
  local success, error_msg = pcall(vim.fn.writefile, { "" }, full_path)
  if not success then
    Utils.notify.warn("Error creating file: " .. error_msg, { title = "File" })
    return
  end
  vim.cmd("e " .. full_path)
  Utils.notify.info(path_and_filename .. " created", { title = "File" })
end

-----------------------------------------------------------
-- Toggle diagnostics
-----------------------------------------------------------
local diagnostics_enabled = true
function M.toggle_diagnostics()
  if vim.diagnostic.is_disabled then
    diagnostics_enabled = not vim.diagnostic.is_disabled()
  end
  diagnostics_enabled = not diagnostics_enabled

  if diagnostics_enabled then
    vim.diagnostic.enable()
  else
    vim.diagnostic.disable()
  end
  Utils.notify[diagnostics_enabled and "info" or "warn"](
    diagnostics_enabled and "Enabled diagnostics" or "Disabled diagnostics",
    { title = "Diagnostics" }
  )
end

-----------------------------------------------------------
-- Toggle line wrap
-----------------------------------------------------------
function M.toggle_line_wrap()
  local wrapped = vim.opt.wrap:get()
  vim.opt.wrap = not wrapped
  Utils.notify[wrapped and "warn" or "info"](
    wrapped and "Line wrap disabled." or "Line wrap enabled.",
    { title = "Option" }
  )
end

-----------------------------------------------------------
-- Toggle spell checking
-----------------------------------------------------------
function M.toggle_spell()
  local spell = vim.opt.spell:get()
  vim.opt.spell = not spell -- Toggle wrap based on current state
  Utils.notify[spell and "warn" or "info"](spell and "Spell disabled." or "Spell enabled.", { title = "Option" })
end

-----------------------------------------------------------
-- Make the current file executable
-----------------------------------------------------------
function M.toggle_file_executable()
  local filename = vim.fn.expand("%:p")
  local cmd, success_message, error_message
  if Utils.is_executable(filename) then
    cmd = "chmod -x " .. filename
    success_message = "File made unexecutable"
    error_message = "Error making file unexecutable"
  else
    cmd = "chmod +x " .. filename
    success_message = "File made executable"
    error_message = "Error making file executable"
  end
  local output = vim.fn.system(cmd)

  if vim.v.shell_error == 0 then
    Utils.notify.info(success_message, { title = "Option" })
  else
    Utils.notify.warn(error_message .. ": " .. output, { title = "Option" })
  end
end

-------------------------------------
-- Duplicate the current line.
-------------------------------------
function M.duplicate_line()
  local current_line = vim.api.nvim_get_current_line() -- Get the current line
  local cursor = vim.api.nvim_win_get_cursor(0) -- Get current cursor position
  vim.api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, { current_line })
  vim.api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] }) -- Move cursor to the duplicated line
end

-------------------------------------
-- Duplicate the currently selected lines in visual mode.
-------------------------------------
function M.duplicate_selection()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local selected_lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, selected_lines)
  local new_cursor_line = math.min(end_line + #selected_lines, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  vim.api.nvim_win_set_cursor(0, { new_cursor_line, 0 })
end

----------------------------------------------------
--- Split a string into words based on its case style
---@param str string The string to split into words
---@return string[] Array of words in lowercase
----------------------------------------------------
local function split_into_words(str)
  -- Handle snake_case
  if str:find("_") then
    local words = {}
    for word in str:gmatch("[^_]+") do
      table.insert(words, word:lower())
    end
    return words
  end

  local words = {}
  local current_word = ""

  for i = 1, #str do
    local char = str:sub(i, i)
    if char:match("[A-Z]") and current_word ~= "" then
      table.insert(words, current_word:lower())
      current_word = char
    else
      current_word = current_word .. char
    end
  end

  if current_word ~= "" then
    table.insert(words, current_word:lower())
  end

  return words
end

----------------------------------------------------
--- Convert array of words to camelCase
---@param words string[] Array of words to convert
---@return string The camelCase string
----------------------------------------------------
local function to_camel_case(words)
  local result = words[1]
  for i = 2, #words do
    result = result .. words[i]:sub(1, 1):upper() .. words[i]:sub(2)
  end
  return result
end

----------------------------------------------------
--- Convert array of words to snake_case
--- @param words string[] Array of words to convert
--- @return string The snake_case string
----------------------------------------------------
local function to_snake_case(words)
  return table.concat(words, "_")
end

----------------------------------------------------
--- Convert a word between camelCase and snake_case
--- @param word string The word to convert
--- @return string The converted word
----------------------------------------------------
local function convert_case(word)
  local words = split_into_words(word)
  if word:find("_") then
    return to_camel_case(words)
  else
    return to_snake_case(words)
  end
end

----------------------------------------------------
--- Check if LSP is available and supports rename for current buffer
--- @return boolean Whether LSP with rename support is available
----------------------------------------------------
local function has_rename_support()
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].buflisted then
    return false
  end

  return Utils.lsp.has(bufnr, "rename")
end

----------------------------------------------------
--- Toggle case of word under cursor with LSP support
--- Uses LSP rename when available, falls back to local change
----------------------------------------------------
function M.toggle_case()
  local current_word = vim.fn.expand("<cword>")
  if current_word == "" then
    return
  end

  local new_word = convert_case(current_word)
  if has_rename_support() then
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = Utils.lsp.get_clients({
      bufnr = bufnr,
      method = "textDocument/rename",
    })
    if #clients > 0 then
      if Utils.has("inc-rename.nvim") then
        vim.cmd("IncRename " .. new_word)
      else
        vim.lsp.buf.rename(new_word)
      end
    else
      local cmd = string.format("normal! ciw%s", new_word)
      vim.cmd(cmd)
      Utils.notify.warn("LSP detached, performed local rename only", { title = "Case Toggle" })
    end
  else
    local cmd = string.format("normal! ciw%s", new_word)
    vim.cmd(cmd)
  end
end

return M
