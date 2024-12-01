---@class utils.cmp
local M = {}

--------------------------------------------------
---Previews a snippet by parsing it with vim.lsp grammar
---If parsing fails, falls back to basic string substitution
---@param snippet string The snippet text to preview
--------------------------------------------------
local function snippet_preview(snippet)
  local ok, parsed = pcall(vim.lsp._snippet_grammar.parse, snippet)
  if ok then
    return tostring(parsed)
  else
    return snippet:gsub("%${%d+:(.-)}", "%1"):gsub("%$%d+", ""):gsub("%$0", "")
  end
end

--------------------------------------------------
---Fixes snippet syntax by normalizing placeholder texts
---@param snippet string The snippet to fix
--------------------------------------------------
local function snippet_fix(snippet)
  local texts = {}
  return snippet:gsub("%$%b{}", function(m)
    local n, name = m:match("^%${(%d+):(.+)}$")
    if n then
      texts[n] = texts[n] or snippet_preview(name)
      return "${" .. n .. ":" .. texts[n] .. "}"
    end
    return m
  end)
end

---Notifies the user about snippet expansion status
---@param success boolean Whether the operation was successful
---@param msg string The message to display
---@param snippet string The snippet that was processed
local function notify_user(success, msg, snippet)
  local status = success and "warn" or "error"
  Utils.notify[status](
    ([[%s
      ```%s
      %s
      ```]]):format(msg, vim.bo.filetype, snippet),
    { title = "vim.snippet" }
  )
end

--------------------------------------------------
---Expands a snippet with error handling and automatic fixing
---@param args table Arguments containing the snippet body
--------------------------------------------------
function M.expand_snippet(args)
  local snippet = args.body
  local session = vim.snippet.active() and vim.snippet._session or nil

  -- Attempt to expand the snippet
  local ok, err = pcall(vim.snippet.expand, snippet)

  if not ok then
    -- Try to fix the snippet and expand again if it fails
    local fixed = snippet_fix(snippet)
    ok = pcall(vim.snippet.expand, fixed)
    local msg = ok and "Failed to parse snippet, but was able to fix it automatically."
      or ("Failed to parse snippet.\n" .. err)
    notify_user(ok, msg, snippet)
  end

  -- Restore the original snippet session if necessary
  if session then
    vim.snippet._session = session
  end
end

return M
