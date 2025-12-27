---@class utils.bigfile
local M = {}
local notify = Utils.notify.create({ title = "Big file", tiemeout = 5000 })

---@return BigFileConfig
local function get_config()
  if not vim.g.bigfile_config then
    vim.g.bigfile = vim.g.bigfile or 1.5 * 1024 * 1024
    vim.g.bigfile_max_lines = vim.g.bigfile_max_lines or 32768
    vim.g.bigfile_config = {
      size = vim.g.bigfile,
      max_lines = vim.g.bigfile_max_lines,
      avg_line_length = 1000,
      sample_lines = 100,
    }
  end
  return vim.g.bigfile_config
end

---@param buf number
---@param is_big boolean
function M.notify(buf, is_big)
  local path = vim.fn.fnamemodify(Utils.get_filepath(buf), ":p:~:.")
  local message = is_big and "Big file detected `%s`. Some features disabled."
    or "File `%s` no longer treated as big file."
  notify[is_big and "warn" or "info"](message:format(path))
end

---Check file size
---@param buf number Buffer number
---@return boolean is_big
local function check_file_size(buf)
  local config = get_config()
  local path = Utils.get_filepath(buf)

  if path and path ~= "" then
    local stat = vim.uv.fs_stat(path)
    if stat and stat.size > config.size then return true end
  end

  return false
end

---Check line count
---@param buf number Buffer number
---@return boolean is_big
local function check_line_count(buf)
  local config = get_config()
  local line_count = vim.api.nvim_buf_line_count(buf)
  return line_count > config.max_lines
end

---Check average line length
---@param buf number Buffer number
---@return boolean is_big
local function check_avg_line_length(buf)
  if not vim.api.nvim_buf_is_loaded(buf) then return false end

  local config = get_config()
  local line_count = vim.api.nvim_buf_line_count(buf)
  local sample_size = math.min(line_count, config.sample_lines)
  local total_size = 0

  for i = 1, sample_size do
    local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
    if line then total_size = total_size + #line end
  end

  local avg_line_length = total_size / sample_size
  return avg_line_length > config.avg_line_length
end

---Check if a buffer contains a big file
---@param buf number Buffer number
---@return boolean is_big Whether the file is considered big
function M.is_big_file(buf)
  return check_file_size(buf) or check_line_count(buf) or check_avg_line_length(buf)
end

---@param buf number
---@param is_big boolean
function M.set_bigfile_options(buf, is_big)
  local ok = pcall(function()
    vim.api.nvim_buf_call(buf, function()
      vim.opt_local.spell = is_big and false or nil
      vim.opt_local.undofile = not is_big
      vim.opt_local.breakindent = not is_big
      vim.opt_local.foldmethod = is_big and "manual" or nil
      vim.opt_local.statuscolumn = is_big and "" or nil
      vim.opt_local.conceallevel = is_big and 0 or nil

      vim.b[buf].copilot_enabled = not is_big
      vim.b[buf].snacks_scroll = not is_big

      if vim.fn.exists(is_big and ":NoMatchParen" or ":DoMatchParen") ~= 0 then
        vim.cmd(is_big and "NoMatchParen" or "DoMatchParen")
      end
    end)
  end)
  if not ok then notify.warn("Failed to set bigfile options for buffer " .. buf) end
end

---@param buf number Buffer number
local function disable_features(buf)
  pcall(vim.cmd, "Copilot disable")
  pcall(vim.cmd, "TSBufDisable highlight")
  pcall(function()
    Utils.treesitter.incr.detach(buf)
  end)

  local ft = vim.bo[buf].filetype
  if ft and ft ~= "" then
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then vim.bo[buf].syntax = ft end
    end)
  end
end

local function enable_features()
  pcall(vim.cmd, "Copilot enable")
  pcall(function()
    Utils.treesitter.incr.attach()
  end)
end

---@param buf number
---@param is_big boolean
function M.apply_big_file_settings(buf, is_big)
  buf = Utils.ensure_buf(buf)

  if vim.b[buf].bigfile == is_big then return end

  vim.b[buf].bigfile = is_big

  if is_big and not vim.b[buf].bigfile_notified then
    notify(buf, is_big)
    vim.b[buf].bigfile_notified = true
  elseif not is_big and vim.b[buf].bigfile_notified then
    vim.b[buf].bigfile_notified = false
  end

  M.set_bigfile_options(buf, is_big)

  if is_big then
    disable_features(buf)
  else
    enable_features()
  end
end

---Debounced check for text changes
---@type table<number, number>
local check_timers = {}

---Schedule a bigfile check with debouncing
---@param buf number Buffer number
---@param delay? number Delay in milliseconds (default: 1000)
local function schedule_check(buf, delay)
  delay = delay or 1000

  -- Cancel existing timer
  if check_timers[buf] then vim.fn.timer_stop(check_timers[buf]) end

  check_timers[buf] = vim.fn.timer_start(delay, function()
    check_timers[buf] = nil
    if vim.api.nvim_buf_is_valid(buf) then
      local big = M.is_big_file(buf)
      M.apply_big_file_settings(buf, big)
    end
  end)
end

function M.setup(opts)
  if opts then vim.g.bigfile_config = vim.tbl_deep_extend("force", get_config(), opts) end
  Utils.autocmd.autocmd_augroup("big_file", {
    {
      events = { "BufReadPre", "BufWritePost" },
      desc = "Detect big files.",
      callback = function(event)
        local buf = event.buf
        local big = M.is_big_file(buf)
        M.apply_big_file_settings(buf, big)
      end,
    },
    {
      events = { "TextChanged", "TextChangedI" },
      desc = "Detect big files.",
      callback = function(event)
        schedule_check(event.buf)
      end,
    },
    {
      events = { "BufDelete" },
      desc = "Clean up timers on buffer delete",
      callback = function(event)
        if check_timers[event.buf] then
          vim.fn.timer_stop(check_timers[event.buf])
          check_timers[event.buf] = nil
        end
      end,
    },
    {
      events = { "FileType" },
      once = true,
      desc = "Prevent treesitter and LSP from attaching to big files.",
      callback = function(event)
        vim.api.nvim_del_autocmd(event.id)

        local ts_get_parser = vim.treesitter.get_parser
        local ts_foldexpr = vim.treesitter.foldexpr
        local lsp_start = vim.lsp.start

        ---@diagnostic disable-next-line: duplicate-set-field
        function vim.treesitter.get_parser(buf, ...)
          buf = Utils.ensure_buf(buf)
          if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].bigfile then
            -- Return fake parser on empty buffer to prevent freezing
            return vim.treesitter._create_parser(
              vim.api.nvim_create_buf(false, true),
              vim.treesitter.language.get_lang(vim.bo.ft) or vim.bo.ft
            )
          end
          return ts_get_parser(buf, ...)
        end

        ---@diagnostic disable-next-line: duplicate-set-field
        function vim.treesitter.foldexpr(...)
          if vim.b.bigfile then return end
          return ts_foldexpr(...)
        end

        ---@diagnostic disable-next-line: duplicate-set-field
        function vim.lsp.start(...)
          if vim.b.bigfile then return end
          return lsp_start(...)
        end
      end,
    },
  })
end

return M
