---@class utils.format
local M = setmetatable({}, {
  __call = function(m, opts)
    return m.format(opts)
  end,
})

local api = vim.api
----------------------------------------------------
-- Check if autoformat is enabled for the given buffer
---@param buf number|nil The buffer to check. Defaults to the current buffer if nil.
---@return boolean Whether autoformat is enabled for the buffer.
----------------------------------------------------
function M.enabled(buf)
  buf = Utils.ensure_buf(buf)
  if vim.b[buf].bigfile then
    return false
  end
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
  local current_buf = Utils.ensure_buf(buf)
  if vim.b[current_buf].bigfile then
    return false
  end

  local gaf = vim.g.autoformat == nil or vim.g.autoformat
  local baf = vim.b[current_buf].autoformat

  if buf then
    if enable == nil then
      enable = not M.enabled(current_buf)
    end
    vim.b[current_buf].autoformat = enable
  else
    if enable == nil then
      if baf == true and not gaf then
        enable = true
      else
        enable = not gaf
      end
    end

    vim.g.autoformat = enable
    if not enable then
      vim.b[current_buf].autoformat = nil
    end
  end

  -- Show status
  local new_gaf = vim.g.autoformat == nil or vim.g.autoformat
  local new_baf = vim.b[current_buf].autoformat
  local enabled = M.enabled(current_buf)

  local lines = {
    "# Status",
    ("- [%s] global **%s**"):format(new_gaf and "x" or " ", new_gaf and "enabled" or "disabled"),
    ("- [%s] buffer **%s**"):format(
      enabled and "x" or " ",
      new_baf == nil and "inherit" or new_baf and "enabled" or "disabled"
    ),
  }

  Utils.notify[enabled and "info" or "warn"](
    lines,
    { title = "AutoFormat (" .. (enabled and "enabled" or "disabled") .. ")" }
  )
end

----------------------------------------------------
--- Format the current buffer using Conform or LSP
---@param opts? table Options for formatting
---@see conform.format
---@see vim.lsp.buf.format
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
  api.nvim_create_autocmd("BufWritePre", {
    group = api.nvim_create_augroup("LazyFormat", { clear = true }),
    callback = function(event)
      if M.enabled() then
        M.format({ bufnr = event.buf, force = true })
      end
    end,
  })
end

return M
