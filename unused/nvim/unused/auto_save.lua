---@class utils.auto_save
--[[
  This module auto save files on different events.
  It only saves in project files and it ignores config files and certain filetypes/buftypes.
--]]

local M = {}
M.config = {
  debounce_delay = 1000,
  exclude_filetypes = { "oil", "neo-tree" },
  exclude_buftypes = { "nofile", "prompt", "terminal" },
  -- path to always include
  include_path = {
    "~/dot-files/config/nvim",
  },
  exclude_path = {
    "~/dot-files",
    "~/.config",
  },
  require_project = true,
}

local debounce_timer = nil

local function path_match(path, patterns)
  patterns = Utils.ensure_list(patterns)
  for _, pattern in ipairs(patterns) do
    local expanded = vim.fn.expand(pattern)
    if path:find(expanded, 1, true) == 1 then return true end
  end
  return false
end

local function is_in_project(buf)
  buf = Utils.ensure_buf(buf)
  local ok, root = pcall(Utils.root.get, buf)
  if not ok or not root then return false end

  local home = vim.fn.expand("~")
  if root == home or root == "/" then return false end

  return true
end

local function should_save(buf)
  if not vim.api.nvim_buf_is_loaded(buf) then return false end
  if not vim.bo[buf].modified or vim.bo[buf].readonly then return false end

  if Utils.ignore_buftype(buf, M.config.exclude_buftypes, true) then return false end

  if Utils.ignore_filetype(buf, M.config.exclude_filetypes, true) then return false end

  local buf_path = vim.api.nvim_buf_get_name(buf)
  if buf_path == "" then return false end

  local file_path = vim.fn.fnamemodify(buf_path, ":p")

  if path_match(file_path, M.config.exclude_path) and not path_match(file_path, M.config.include_path) then
    return false
  end
  if path_match(file_path, M.config.include_path) then return true end

  if M.config.require_project then return is_in_project(buf) end

  return true
end

function M.save_buffers(buf)
  local ok = pcall(function()
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("silent! noautocmd write")
    end)
  end)
  return ok
end

function M.do_save()
  local buf = Utils.ensure_buf(0)
  if should_save(buf) then M.save_buffers(buf) end
end

local function trigger_save()
  if debounce_timer then debounce_timer:stop() end
  debounce_timer = vim.defer_fn(function()
    M.do_save()
  end, M.config.debounce_delay)
end

function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
  Utils.autocmd.autocmd_augroup("auto_save", {
    {
      events = { "InsertLeave", "TextChanged" },
      callback = function()
        trigger_save()
      end,
    },
    {
      events = { "FocusLost", "BufLeave" },
      callback = function()
        if debounce_timer then debounce_timer:stop() end
        M.do_save()
      end,
    },
  })
end

return M
