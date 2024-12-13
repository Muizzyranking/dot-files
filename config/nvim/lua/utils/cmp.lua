---@class utils.cmp
local M = {}

--------------------------------------------------
---Previews a snippet by parsing it with vim.lsp grammar
---@param snippet string The snippet text to preview
---@return string The preview text
--------------------------------------------------
function M.snippet_preview(snippet)
  local ok, parsed = pcall(vim.lsp._snippet_grammar.parse, snippet)
  if ok then
    return tostring(parsed)
  else
    ---@diagnostic disable-next-line: redundant-return-value
    return snippet:gsub("%${%d+:(.-)}", "%1"):gsub("%$%d+", ""):gsub("%$0", "")
  end
end

--------------------------------------------------
---Replaces placeholders in a snippet using a callback function
---@param snippet string The snippet to process
---@param fn function The callback function to process each placeholder
---@return string The processed snippet
--------------------------------------------------
function M.snippet_replace(snippet, fn)
  return snippet:gsub("%$%b{}", function(m)
    local n, name = m:match("^%${(%d+):(.+)}$")
    return n and fn({ n = n, text = name }) or m
  end) or snippet
end

--------------------------------------------------
---Fixes snippet syntax by normalizing placeholder texts
---@param snippet string The snippet to fix
---@return string The fixed snippet
--------------------------------------------------
function M.snippet_fix(snippet)
  local texts = {} ---@type table<number, string>
  return M.snippet_replace(snippet, function(placeholder)
    texts[placeholder.n] = texts[placeholder.n] or M.snippet_preview(placeholder.text)
    return "${" .. placeholder.n .. ":" .. texts[placeholder.n] .. "}"
  end)
end

--------------------------------------------------
---Expands a snippet with error handling and automatic fixing
---@param args string The snippet to expand
--------------------------------------------------
function M.expand_snippet(args)
  local snippet = args.body
  -- Native sessions don't support nested snippet sessions.
  -- Always use the top-level session.
  local session = vim.snippet.active() and vim.snippet._session or nil

  -- Attempt to expand the snippet
  local ok, err = pcall(vim.snippet.expand, snippet)
  if not ok then
    -- Try to fix the snippet and expand again
    local fixed = M.snippet_fix(snippet)
    ok = pcall(vim.snippet.expand, fixed)
    local msg = ok and "Failed to parse snippet, but was able to fix it automatically."
      or ("Failed to parse snippet.\n" .. err)

    -- Use your notification system here
    Utils.notify[ok and "warn" or "error"](
      ([[%s
```%s
%s
```]]):format(msg, vim.bo.filetype, snippet),
      { title = "vim.snippet" }
    )
  end

  -- Restore the original snippet session if necessary
  if session then
    vim.snippet._session = session
  end
end

return M
