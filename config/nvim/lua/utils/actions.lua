---@class utils.actions
local M = {}
local api = vim.api

-----------------------------------------------------------
-- Make the current file executable
-----------------------------------------------------------
function M.toggle_file_executable(state)
  local filename = vim.fn.expand("%:p")
  local cmd = ("chmod %s %s"):format(state and "-x" or "+x", filename)
  local success_message = ("File made %s"):format(state and "unexecutable" or "executable")
  local error_message = ("Error making file %s"):format(state and "unexecutable" or "executable")

  local output = vim.fn.system(cmd)
  local err = vim.v.shell_error == 0
  Utils.notify[err and "info" or "warn"](
    err and success_message or error_message .. ": " .. output,
    { title = "Options" }
  )
end

-------------------------------------
-- Duplicate the current line.
-------------------------------------
function M.duplicate_line()
  local current_line = api.nvim_get_current_line() -- Get the current line
  local cursor = api.nvim_win_get_cursor(0) -- Get current cursor position
  api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, { current_line })
  api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] }) -- Move cursor to the duplicated line
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
  local selected_lines = api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  api.nvim_buf_set_lines(0, end_line, end_line, false, selected_lines)
  local new_cursor_line = math.min(end_line + #selected_lines, api.nvim_buf_line_count(0))
  api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
  api.nvim_win_set_cursor(0, { new_cursor_line, 0 })
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
--- Convert array of words to PascalCase
---@param words string[] Array of words to convert
---@return string The PascalCase string
----------------------------------------------------
local function to_pascal_case(words)
  local result = ""
  for _, word in ipairs(words) do
    result = result .. word:sub(1, 1):upper() .. word:sub(2)
  end
  return result
end

----------------------------------------------------
--- Convert array of words to snake_case
---@param words string[] Array of words to convert
---@return string The snake_case string
----------------------------------------------------
local function to_snake_case(words)
  return table.concat(words, "_")
end

----------------------------------------------------
--- Detect the current case style of a word
---@param word string The word to analyze
---@return string The detected case style
----------------------------------------------------
local function detect_case_style(word)
  if word:find("_") then
    return "snake_case"
  elseif word:sub(1, 1):match("[A-Z]") then
    return "PascalCase"
  else
    return "camelCase"
  end
end

----------------------------------------------------
--- Convert a word to the specified case style
---@param word string The word to convert
---@param target_case string The target case style
---@return string The converted word
----------------------------------------------------
local function convert_to_case(word, target_case)
  local words = split_into_words(word)
  if target_case == "camelCase" then
    return to_camel_case(words)
  elseif target_case == "PascalCase" then
    return to_pascal_case(words)
  else -- snake_case
    return to_snake_case(words)
  end
end

----------------------------------------------------
--- Check if LSP is available and supports rename for current buffer
---@return boolean Whether LSP with rename support is available
----------------------------------------------------
local function has_rename_support()
  local bufnr = api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].buflisted then
    return false
  end
  return Utils.lsp.has(bufnr, "rename")
end

----------------------------------------------------
--- Show case style selection menu and apply conversion
---@param current_word string The word to convert
---@param current_case string The current case style
----------------------------------------------------
local function show_case_selection(current_word, current_case)
  local case_styles = {
    { text = "camelCase", value = "camelCase" },
    { text = "PascalCase", value = "PascalCase" },
    { text = "snake_case", value = "snake_case" },
  }

  -- Remove current case style from options
  for i, style in ipairs(case_styles) do
    if style.value == current_case then
      table.remove(case_styles, i)
      break
    end
  end

  vim.ui.select(case_styles, {
    prompt = "Select target case style:",
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if choice then
      local new_word = convert_to_case(current_word, choice.value)

      if has_rename_support() then
        local bufnr = api.nvim_get_current_buf()
        local clients = Utils.lsp.get_clients({
          bufnr = bufnr,
          method = "textDocument/rename",
        })
        if #clients > 0 then
          if Utils.has("inc-rename.nvim") and pcall(require, "inc_rename") then
            vim.cmd("nohlsearch")
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
  end)
end

----------------------------------------------------
--- Toggle case of word under cursor with LSP support
--- Uses LSP rename when available, falls back to local change
----------------------------------------------------
function M.change_var_case()
  local current_word = vim.fn.expand("<cword>")
  if current_word == "" then
    return
  end

  local current_case = detect_case_style(current_word)
  show_case_selection(current_word, current_case)
end

return M
