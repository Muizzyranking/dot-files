---@class utils.notify
---@field warn fun(msg: string|table, opts?: table): integer
---@field error fun(msg: string|table, opts?: table): integer
---@field info fun(msg: string|table, opts?: table): integer

local M = setmetatable({}, {
  ---@param msg string|table
  ---@param opts? table
  __call = function(m, msg, opts)
    return m.notify(msg, opts)
  end,
  __index = function(m, key)
    return function(msg, opts)
      opts = opts or {}
      opts.level = opts.level or vim.log.levels[key:upper()]
      return m.notify(msg, opts)
    end
  end,
})

----------------------------------------------------------
--- Wrapper function for Neovim's notification system
---@param msg string|table The message to be displayed in the notification
---@param opts? table Additional options for the notification
----------------------------------------------------------
function M.notify(msg, opts)
  if vim.in_fast_event() then
    return vim.schedule(function()
      M.notify(msg, opts)
    end)
  end
  opts = opts or {}
  if type(msg) == "table" then
    msg = table.concat(
      vim.tbl_filter(function(line)
        return line or false
      end, msg),
      "\n"
    )
  end
  local lang = opts.lang or "markdown"
  local n = opts.once and vim.notify_once or vim.notify
  n(msg, opts.level or vim.log.levels.INFO, {
    on_open = function(win)
      local ok = pcall(function()
        vim.treesitter.language.add("markdown")
      end)
      if not ok then pcall(require, "nvim-treesitter") end
      vim.wo[win].conceallevel = 3
      vim.wo[win].concealcursor = ""
      vim.wo[win].spell = false
      local buf = vim.api.nvim_win_get_buf(win)
      if not pcall(vim.treesitter.start, buf, lang) then
        vim.bo[buf].filetype = lang
        vim.bo[buf].syntax = lang
      end
    end,
    title = opts.title or "NVIM",
  })
end

----------------------------------------------------------
--- Creates a notification function with shared options
---@param shared_opts? table Shared options to merge with each notification (e.g., {title = "LSP"})
---@return table A callable table with notification methods (info, warn, error, etc.)
----------------------------------------------------------
function M.create(shared_opts)
  shared_opts = shared_opts or {}
  return setmetatable({}, {
    ---@param msg string|table
    ---@param opts? table
    __call = function(_, msg, opts)
      opts = vim.tbl_extend("force", shared_opts, opts or {})
      return M.notify(msg, opts)
    end,
    __index = function(_, key)
      return function(msg, opts)
        opts = vim.tbl_extend("force", shared_opts, opts or {})
        opts.level = opts.level or vim.log.levels[key:upper()]
        return M.notify(msg, opts)
      end
    end,
  })
end

return M
