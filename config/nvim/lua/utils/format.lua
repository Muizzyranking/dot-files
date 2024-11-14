---@class utils.format
local M = {}

M.formatters = {}
----------------------------------------------------
-- Register a formatter
---@param formatter table The formatter to register
----------------------------------------------------
function M.register(formatter)
  M.formatters[#M.formatters + 1] = formatter
  table.sort(M.formatters, function(a, b)
    return a.priority > b.priority
  end)
end

----------------------------------------------------
-- Resolve and return a list of active formatters
---@param buf number|nil The buffer to resolve the formatters for. If nil, the current buffer is used.
---@return table A list of formatters with their active status and resolved sources
----------------------------------------------------
function M.resolve(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local have_primary = false
  ---@param formatter LazyFormatter
  return vim.tbl_map(function(formatter)
    local sources = formatter.sources(buf)
    local active = #sources > 0 and (not formatter.primary or not have_primary)
    have_primary = have_primary or (active and formatter.primary) or false
    return setmetatable({
      active = active,
      resolved = sources,
    }, { __index = formatter })
  end, M.formatters)
end

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
-- Format the given buffer using the available formatters
---@param opts table|nil Options for formatting. Can include:
--   - buf (number|nil): The buffer to format. Defaults to the current buffer.
--   - force (boolean): Whether to force formatting even if not enabled.
----------------------------------------------------
function M.format(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  if not ((opts and opts.force) or M.enabled(buf)) then
    return
  end

  local done = false
  for _, formatter in ipairs(M.resolve(buf)) do
    if formatter.active then
      done = true
      require("lazy.core.util").try(function()
        return formatter.format(buf)
      end, { msg = "Formatter `" .. formatter.name .. "` failed" })
    end
  end

  if not done and opts and opts.force then
    Utils.notify.warn("No formatter available", { title = "LazyVim" })
  end
end

----------------------------------------------------
---Enable or disable autoformat
---@param enable boolean
---@param buf? number
----------------------------------------------------
local function format_enable(enable, buf)
  if enable == nil then
    enable = true
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
  local enabled = M.format_enabled(buf)

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
---Toggle autoformat state for a buffer
---@param buf? number
----------------------------------------------------
function M.toggle_autoformat(buf)
  local enabled = M.format_enabled(buf)
  format_enable(not enabled, buf)

  Utils.notify[enabled and "warn" or "info"](
    (enabled and "Disabled" or "Enabled") .. " autoformat",
    { title = "AutoFormat" }
  )
end

----------------------------------------------------
-- Setup autoformat on save
----------------------------------------------------
function M.setup()
  -- Autoformat autocmd
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("LazyFormat", {}),
    callback = function(event)
      M.format({ buf = event.buf })
    end,
  })
end
return M
