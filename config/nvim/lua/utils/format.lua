---@class utils.format
local M = setmetatable({}, {
  __call = function(m, opts)
    return m.format(opts)
  end,
})

---@class utils.FormatterConfig
---@field name string Identifier for the formatter
---@field priority number Higher number = higher priority
---@field filetypes? string[] Optional list of filetypes (nil = global)
---@field check? fun(buf: number): boolean Optional check if formatter is available
---@field format fun(opts: table) The actual formatting function

---@type utils.FormatterConfig[]
M.formatters = {}
local did_setup = false

local api = vim.api
----------------------------------------------------
-- Check if autoformat is enabled for the given buffer
---@param buf? number The buffer to check. Defaults to the current buffer if nil.
---@return boolean Whether autoformat is enabled for the buffer.
----------------------------------------------------
function M.enabled(buf)
  buf = Utils.ensure_buf(buf)
  if vim.b[buf].bigfile then return false end
  local gaf = vim.g.autoformat
  local baf = vim.b[buf].autoformat

  if baf ~= nil then return baf end

  return gaf == nil or gaf
end

----------------------------------------------------
--- Toggle autoformat for a buffer or globally
--- @param buf? number Buffer number to toggle (optional)
--- @param enable? boolean Explicitly enable or disable (optional)
----------------------------------------------------
function M.toggle(buf, enable)
  local current_buf = Utils.ensure_buf(buf)
  if vim.b[current_buf].bigfile then return false end

  local gaf = vim.g.autoformat == nil or vim.g.autoformat
  local baf = vim.b[current_buf].autoformat

  if buf then
    if enable == nil then enable = not M.enabled(current_buf) end
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
    if not enable then vim.b[current_buf].autoformat = nil end
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

---@param config utils.FormatterConfig
function M.register(config)
  assert(config.name, "Formatter must have a name")
  assert(type(config.format) == "function", "Formatter must have a format function")
  config.priority = config.priority or 1
  table.insert(M.formatters, config)
  table.sort(M.formatters, function(a, b)
    return a.priority > b.priority
  end)
  if config.filetypes then
    for _, buf in ipairs(api.nvim_list_bufs()) do
      if api.nvim_buf_is_loaded(buf) then
        local ft = vim.bo[buf].filetype
        if vim.tbl_contains(config.filetypes, ft) then M.cache_formatter(buf) end
      end
    end
  else
    for _, buf in ipairs(api.nvim_list_bufs()) do
      if api.nvim_buf_is_loaded(buf) then M.cache_formatter(buf) end
    end
  end
  if did_setup then Utils.autocmd.exec_user_event("FormatterRegistered", { config = config }) end
end

---@param buf? number
---@return utils.FormatterConfig[]
function M.get_formatters(buf)
  buf = Utils.ensure_buf(buf)
  local ft = vim.bo[buf].filetype
  local formatters = {}
  for _, formatter in ipairs(M.formatters) do
    -- stylua: ignore
    if not formatter.filetypes or vim.tbl_contains(formatter.filetypes, ft) then
      table.insert(formatters, formatter)
    end
  end
  table.sort(formatters, function(a, b)
    return a.priority > b.priority
  end)
  return formatters
end

---@param buf? number
---@return utils.FormatterConfig?
function M.resolve_formatter(buf)
  local formatters = vim.b[buf].formatters
  if not formatters then formatters = M.get_formatters(buf) end
  for _, formatter in ipairs(formatters) do
    if not formatter.check then return formatter end
    local ok, result = pcall(formatter.check, buf)
    if ok and result then return formatter end
  end
  return nil
end

---@param buf? number
function M.cache_formatter(buf)
  if vim.b[buf].formatters_cached then return end
  local formatters = M.get_formatters(buf)
  vim.b[buf].formatters = formatters
  vim.b[buf].formatters_cached = true
end

----------------------------------------------------
--- Invalidate cache for a buffer (force recache on next access)
---@param buf number Buffer number
----------------------------------------------------
function M.invalidate_cache(buf)
  vim.b[buf].formatters = nil
  vim.b[buf].formatters_cached = nil
end

----------------------------------------------------
--- Format the current buffer using Conform or LSP
---@param opts? table Options for formatting
---@see conform.format
---@see vim.lsp.buf.format
----------------------------------------------------
function M.format(opts)
  opts = opts or {}
  local buf = Utils.ensure_buf(opts.bufnr)
  local formatter = vim.b[buf].formatter
  if not formatter then
    formatter = M.resolve_formatter(buf)
    vim.b[buf].formatter = formatter
  end
  local ok, err = pcall(function()
    formatter.format(vim.tbl_extend("force", opts or {}, { bufnr = buf }))
  end)
  if not ok then Utils.notify.error("Formatting failed: " .. tostring(err), { title = "Format Error" }) end
end

function M.setup()
  local au_group = Utils.autocmd.augroup("lazyformatter")
  Utils.autocmd.autocmd_augroup(au_group, {
    {
      events = { "FileType" },
      callback = function(event)
        M.cache_formatter(event.buf)
      end,
    },
    {
      events = { "LspAttach" },
      callback = function(event)
        local buffer = event.buf
        M.invalidate_cache(buffer)
        M.cache_formatter(buffer)
      end,
    },
    {
      events = { "BufWritePre" },
      callback = function(event)
        if M.enabled() then M.format({ bufnr = event.buf, force = true }) end
      end,
    },
  })
  Utils.lsp.on_dynamic_capability(function(_, buf)
    M.invalidate_cache(buf)
    M.cache_formatter(buf)
  end, { group = au_group })

  Utils.lsp.on_support_methods("textDocument/formatting", function(_, buf)
    M.invalidate_cache(buf)
    M.cache_formatter(buf)
  end)

  Utils.autocmd.on_user_event("FormatterRegistered", function()
    for _, buf in ipairs(api.nvim_list_bufs()) do
      if api.nvim_buf_is_loaded(buf) then M.cache_formatter(buf) end
    end
  end, { group = au_group })
end

function M.debug(buf)
  buf = buf or api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local formatters = vim.b[buf].formatters or M.get_formatters(buf)
  local resolved = M.resolve_formatter(buf)

  local lines = { "# Formatters for " .. ft }
  table.insert(lines, "")
  table.insert(lines, "## Registered (sorted by priority)")

  if #formatters == 0 then
    table.insert(lines, "*No formatters registered*")
  else
    for i, formatter in ipairs(formatters) do
      local available = "?"
      if formatter.check then
        local ok, result = pcall(formatter.check, buf)
        available = ok and result and "✓" or "✗"
      else
        available = "✓"
      end

      local is_active = resolved and resolved.name == formatter.name and " **(active)**" or ""
      local fts = formatter.filetypes and (" [" .. table.concat(formatter.filetypes, ", ") .. "]") or " [global]"

      table.insert(
        lines,
        string.format(
          "%d. [%s] **%s** (priority: %d)%s%s",
          i,
          available,
          formatter.name,
          formatter.priority,
          fts,
          is_active
        )
      )
    end
  end

  table.insert(lines, "")
  table.insert(lines, "## Currently Active")
  if resolved then
    table.insert(lines, "**" .. resolved.name .. "**")
  else
    table.insert(lines, "*None*")
  end

  -- Add cache status
  table.insert(lines, "")
  table.insert(lines, "## Cache Status")
  table.insert(lines, vim.b[buf].formatters_cached and "Cached ✓" or "Not cached")

  Utils.notify.info(lines, { title = "Format Debug" })
end

return M
