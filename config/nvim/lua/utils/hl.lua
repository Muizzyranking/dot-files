---@class utils.hl
local M = {}
M._highlights = {}
M._highlight_definitions = {}

------------------------------------------------------------------------------
-- Get the color of a highlight group
---@param name string
---@param ground? "fg"|"bg"
---@return string?
------------------------------------------------------------------------------
function M.get_hl_color(name, ground)
  ground = ground or "fg"
  assert(ground == "fg" or ground == "bg", "ground must be 'fg' or 'bg'")
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  local color = hl and (ground == "fg" and (hl.fg or hl.foreground) or (hl.bg or hl.background))
  return color and ("#%06x"):format(color) or nil
end

function M.process_hl(opts)
  local process_opts = vim.deepcopy(opts)
  local base = {}

  if process_opts.link then
    if type(process_opts.link) == "string" then
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = process_opts.link, link = false })
      base = ok and hl or {}
    elseif type(process_opts.link) == "table" then
      local name = process_opts.link.name
      local attrs = process_opts.link.attrs
      if name then
        if attrs and #attrs > 0 then
          for _, attr in ipairs(attrs) do
            base[attr] = M.get_hl_color(name, attr)
          end
        else
          local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
          base = ok and hl or {}
        end
      end
    end
    process_opts.link = nil
  end
  return vim.tbl_deep_extend("force", {}, base, process_opts)
end

-----------------------------------------------
-- add/override highlights
---@param highlights table<string, table>
-----------------------------------------------
function M.add_highlights(highlights)
  local new_hls = {}
  for group, opts in pairs(highlights) do
    local hl_name = opts.name or group
    opts.name = nil
    M._highlight_definitions[hl_name] =
      vim.tbl_deep_extend("force", M._highlight_definitions[hl_name] or {}, vim.deepcopy(opts))

    local processed_opts = M.process_hl(opts)
    M._highlights[hl_name] = vim.tbl_extend("force", M._highlights[hl_name] or {}, processed_opts)
    new_hls[hl_name] = M._highlights[hl_name]
  end
  if M._is_setup then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "HighlightsAdded",
      data = { hls = new_hls },
    })
  end
end

function M.reprocess_highlights()
  local new_hls = {}

  for hl_name, opts in pairs(M._highlight_definitions) do
    local processed_opts = M.process_hl(opts)
    M._highlights[hl_name] = processed_opts
    new_hls[hl_name] = processed_opts
  end

  return new_hls
end

-----------------------------------------------
-- apply the highlights
-----------------------------------------------
function M.setup()
  local ok, hl_config = pcall(require, "config.hl")
  if ok then
    M.add_highlights(hl_config or {})
  end

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("HL ColorScheme", { clear = true }),
    callback = function()
      local updated_hls = M.reprocess_highlights()
      for group, opts in pairs(updated_hls) do
        vim.api.nvim_set_hl(0, group, opts)
      end
    end,
  })

  for group, opts in pairs(M._highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
