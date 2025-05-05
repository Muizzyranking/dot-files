---@class utils.copilotManager
-- This module handles copilot enable/disable when connected to the internet
-- disables copilot on network disconnet and then attaches if regain network
local M = {}

-- State tracking
M.first_check = true
M.session_loading = false
M.ignore_next_check = false

---@param msg string
---@param silent? boolean
---@param level? "info" | "warn" | "error"
function M.notify(msg, silent, level)
  level = level or "info"

  -- Skip info notifications on first check or during session loading
  if (M.first_check or M.session_loading) and level == "info" then
    return
  end

  -- Honor explicit silent flag
  if silent then
    return
  end

  -- Otherwise show notification
  Utils.notify[level](msg, { title = "Copilot Manager" })
end

---@class utils.copilot.ToggleOptions
---@field silent? boolean

---@param has_internet boolean
---@param opts utils.copilot.ToggleOptions
local function handle_internet_change(has_internet, opts)
  local copilot_command = require("copilot.command")

  if has_internet then
    M.notify("Internet connection restored", opts.silent)
    if not vim.g.copilot_enabled then
      copilot_command.enable()
      vim.g.copilot_enabled = true
      M.notify("Copilot has been enabled", opts.silent)
      -- Attach Copilot to current buffer if appropriate
      if vim.bo.buftype == "" and vim.bo.modifiable then
        copilot_command.attach({ force = true })
      end
    end
  else
    M.notify("Internet connection lost", opts.silent)
    if vim.g.copilot_enabled ~= false then
      copilot_command.disable()
      vim.g.copilot_enabled = false
      M.notify("Copilot has been disabled", opts.silent, "warn")
    end
  end
end

---@param opts? utils.copilot.ToggleOptions
function M.toggle_copilot(opts)
  opts = opts or {}
  opts.silent = opts.silent or false

  -- If we should ignore this check, reset flag and return early
  if M.ignore_next_check then
    M.ignore_next_check = false
    return
  end

  local on_exit = function(_, exit_code, _)
    local has_internet_now = (exit_code == 0)

    vim.schedule(function()
      -- Only handle state changes
      if has_internet_now ~= vim.g.has_internet then
        vim.g.has_internet = has_internet_now
        handle_internet_change(has_internet_now, opts)
      end

      -- Mark first check as complete
      M.first_check = false
    end)
  end

  vim.fn.jobstart("ping -c 1 -W 1 github.com", {
    on_exit = on_exit,
    detach = true,
  })
end

function M.init()
  vim.g.has_internet = vim.g.has_internet or false
  vim.g.copilot_enabled = vim.g.has_internet
  vim.g.last_internet_check = os.time()

  -- If VimEnter already happened, we're not on first startup
  if vim.g.vim_enter then
    M.first_check = false
  end

  M.toggle_copilot({ silent = true })
end

function M.setup()
  local augroup = vim.api.nvim_create_augroup("CopilotNetworkManager", { clear = true })
  vim.g.vim_enter = vim.g.vim_enter or false

  -- Add session load tracking
  vim.api.nvim_create_autocmd("User", {
    pattern = "PersistenceLoadPre",
    group = augroup,
    callback = function()
      M.session_loading = true
      -- Skip the next check that might be triggered by buffer events during session load
      M.ignore_next_check = true
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "PersistenceLoadPost",
    group = augroup,
    callback = function()
      -- Run a silent check after session load
      vim.defer_fn(function()
        M.toggle_copilot({ silent = true })
        M.session_loading = false
        vim.g.last_internet_check = os.time()
      end, 300)
    end,
  })

  -- Handle VimEnter event
  if not vim.g.vim_enter then
    vim.api.nvim_create_autocmd("VimEnter", {
      group = augroup,
      callback = function()
        vim.defer_fn(function()
          vim.g.vim_enter = true
          if not M.session_loading then
            M.toggle_copilot({ silent = true })
          end
        end, 100)
      end,
      once = true,
    })
  else
    vim.schedule(function()
      if not M.session_loading then
        M.toggle_copilot({ silent = true })
      end
    end)
  end

  -- Regular checks
  vim.api.nvim_create_autocmd("CursorHold", {
    group = augroup,
    callback = function()
      -- Skip checks while session is loading
      if M.session_loading then
        return
      end

      local current_time = os.time()
      if not vim.g.last_internet_check or (current_time - vim.g.last_internet_check) >= 300 then
        M.toggle_copilot({ silent = false })
        vim.g.last_internet_check = current_time
      end
    end,
  })

  -- Check on focus regain
  vim.api.nvim_create_autocmd("FocusGained", {
    group = augroup,
    callback = function()
      -- Skip checks while session is loading
      if M.session_loading then
        return
      end

      M.toggle_copilot({ silent = false })
      vim.g.last_internet_check = os.time()
    end,
  })

  -- Check when entering a buffer without internet
  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function()
      -- Skip checks while session is loading
      if M.session_loading then
        return
      end

      if vim.g.has_internet == false then
        M.toggle_copilot({ silent = false })
      end
    end,
  })

  M.init()
end

function M.check_now()
  M.toggle_copilot()
  vim.g.last_internet_check = os.time()
  return vim.g.has_internet
end

return M
