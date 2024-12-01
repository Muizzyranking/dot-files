---@class utils.format
local M = {}

----------------------------------------------------
-- Check if autoformat is enabled for the given buffer
---@param buf number|nil The buffer to check. Defaults to the current buffer if nil.
---@return boolean Whether autoformat is enabled for the buffer.
----------------------------------------------------
function M.enabled(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local gaf = vim.g.autoformat
  local baf = vim.b[buf].autoformat

  -- If the buffer has a local value, use that
  if baf ~= nil then
    return baf
  end

  -- Otherwise use the global value if set, or true by default
  return gaf == nil or gaf
end

----------------------------------------------------
--- Toggle autoformat for a buffer or globally
--- @param buf? number Buffer number to toggle (optional)
--- @param enable? boolean Explicitly enable or disable (optional)
----------------------------------------------------
function M.toggle(buf, enable)
  if enable == nil then
    enable = not M.enabled(buf)
  end
  if buf then
    vim.b.autoformat = enable
  else
    vim.g.autoformat = enable
    vim.b.autoformat = nil
  end

  -- Show format status
  local gaf = vim.g.autoformat == nil or vim.g.autoformat
  local baf = vim.b[buf or vim.api.nvim_get_current_buf()].autoformat
  local enabled = M.enabled(buf)

  local lines = {
    "# Status",
    ("- [%s] global **%s**"):format(gaf and "x" or " ", gaf and "enabled" or "disabled"),
    ("- [%s] buffer **%s**"):format(
      enabled and "x" or " ",
      baf == nil and "inherit" or baf and "enabled" or "disabled"
    ),
  }

  Utils.notify[enabled and "info" or "warn"](
    table.concat(lines, "\n"),
    { title = "AutoFormat (" .. (enabled and "enabled" or "disabled") .. ")" }
  )
end

----------------------------------------------------
--- Format the current buffer using Conform or LSP
--- @param opts? table Options for formatting
--- @see conform.format
--- @see vim.lsp.buf.format
----------------------------------------------------
function M.format(opts)
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format(opts)
  else
    vim.lsp.buf.format(opts)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("LazyFormat", {}),
    callback = function(event)
      if M.enabled() then
        M.format({ force = true })
      end
    end,
  })
end

return M
