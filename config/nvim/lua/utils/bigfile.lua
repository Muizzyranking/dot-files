---@class utils.bigfile
local M = {}

local create_autocmd = vim.api.nvim_create_autocmd
local bigfile_group = vim.api.nvim_create_augroup("Bigfile", { clear = true })

---@param buf number
---@param is_big boolean
function M.notify(buf, is_big)
  local path = vim.fn.fnamemodify(Utils.get_filename(buf), ":p:~:.")
  local message = is_big and "Big file detected `%s`. Some features disabled."
    or "File `%s` no longer treated as big file."
  Utils.notify[is_big and "warn" or "info"](message:format(path), { title = "Big file", timeout = 5000 })
end

---@param buf number
---@param is_big boolean
function M.set_bigfile_options(buf, is_big)
  pcall(function()
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
end

---@param buf number
function M.is_big_file(buf)
  vim.g.bigfile = vim.g.bigfile or 1.5 * 1024 * 1024
  vim.g.bigfile_max_lines = vim.g.bigfile_max_lines or 32768
  local path = Utils.get_filename(buf)
  if path and path ~= "" then
    local stat = vim.uv.fs_stat(path)
    if stat and stat.size > vim.g.bigfile then
      return true
    end
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count > vim.g.bigfile_max_lines then
    return true
  end

  if vim.api.nvim_buf_is_loaded(buf) then
    local sample_size = math.min(line_count, 100)
    local total_size = 0

    for i = 1, sample_size do
      local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
      total_size = total_size + #line
    end

    local avg_line_length = total_size / sample_size
    if avg_line_length > 1000 then
      return true
    end
  end

  return false
end

---@param buf number
---@param is_big boolean
function M.apply_big_file_settings(buf, is_big)
  buf = Utils.ensure_buf(buf)
  if vim.b[buf].bigfile == is_big then
    return
  end
  vim.b[buf].bigfile = is_big

  if not vim.b[buf].bigfile_notified then
    if is_big then
      M.notify(buf, is_big)
      vim.b[buf].bigfile_notified = true
    end
  elseif not is_big then
    vim.b[buf].bigfile_notified = false
  end

  M.set_bigfile_options(buf, is_big)
  if is_big then
    pcall(vim.cmd, "Copilot disable")
    vim.cmd("TSBufDisable highlight")
    vim.cmd("TSBufDisable incremental_selection")

    -- Handle filetype-specific syntax
    local ft = vim.bo[buf].filetype
    if ft and ft ~= "" then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.bo[buf].syntax = ft
        end
      end)
    end
  else
    pcall(vim.cmd, "Copilot enable")
    pcall(vim.cmd, "TSBufEnable incremental_selection")
  end
end

function M.setup()
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
        if vim.b[event.buf].bigfile_check_timer then
          vim.fn.timer_stop(vim.b[event.buf].bigfile_check_timer)
        end

        vim.b[event.buf].bigfile_check_timer = vim.fn.timer_start(1000, function()
          local buf = event.buf
          if vim.api.nvim_buf_is_valid(buf) then
            local big = M.is_big_file(buf)
            M.apply_big_file_settings(buf, big)
          end
        end)
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
          -- HACK: Getting parser for a big buffer can freeze nvim, so return a
          -- fake parser on an empty buffer if current buffer is big
          if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].bigfile then
            return vim.treesitter._create_parser(
              vim.api.nvim_create_buf(false, true),
              vim.treesitter.language.get_lang(vim.bo.ft) or vim.bo.ft
            )
          end
          return ts_get_parser(buf, ...)
        end

        ---@diagnostic disable-next-line: duplicate-set-field
        function vim.treesitter.foldexpr(...)
          if vim.b.bigfile then
            return
          end
          return ts_foldexpr(...)
        end

        ---@diagnostic disable-next-line: duplicate-set-field
        function vim.lsp.start(...)
          if vim.b.bigfile then
            return
          end
          return lsp_start(...)
        end
      end,
    },
  })
end

return M
