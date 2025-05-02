---@class utils.copilotManager

-- This module handles copilot enable/disable when connected to the internet
-- disables copilot on network disconnet and then attaches if regain network
local M = {}

M.first_check = true

---@param msg string
---@param silent? boolean
---@param level? "info" | "warn" | "error"
function M.notify(msg, silent, level)
  level = level or "info"
  silent = M.is_silent(level, silent)
  if not silent then
    Utils.notify[level](msg, { title = "Copilot Manager" })
  end
end

---@param level? "info" | "warn" | "error"
---@param silent? boolean
---@return boolean
M.is_silent = function(level, silent)
  if silent == true then
    return true
  end

  if M.first_check and not vim.g.vim_enter and level == "info" then
    return true
  end
  return false
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

  local on_exit = function(_, exit_code, _)
    local has_internet_now = (exit_code == 0)

    if has_internet_now ~= vim.g.has_internet then
      vim.schedule(function()
        vim.g.has_internet = has_internet_now
        handle_internet_change(has_internet_now, opts)
      end)
    end

    if M.first_check then
      M.first_check = false
    end
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
  if vim.g.vim_enter then
    M.first_check = false
  end
  M.toggle_copilot({ silent = true }) -- Silent initial check
end

function M.setup()
  local augroup = vim.api.nvim_create_augroup("CopilotNetworkManager", { clear = true })

  vim.g.vim_enter = vim.g.vim_enter or false

  if not vim.g.vim_enter then
    vim.api.nvim_create_autocmd("VimEnter", {
      group = augroup,
      callback = function()
        vim.defer_fn(function()
          vim.g.vim_enter = true
          M.toggle_copilot()
        end, 100)
      end,
      once = true,
    })
  else
    vim.schedule(function()
      M.toggle_copilot()
    end)
  end

  vim.api.nvim_create_autocmd("CursorHold", {
    group = augroup,
    callback = function()
      local current_time = os.time()
      if not vim.g.last_internet_check or (current_time - vim.g.last_internet_check) >= 300 then
        M.toggle_copilot({ silent = false })
        vim.g.last_internet_check = current_time
      end
    end,
  })

  vim.api.nvim_create_autocmd("FocusGained", {
    group = augroup,
    callback = function()
      M.toggle_copilot({ silent = false })
      vim.g.last_internet_check = os.time()
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function()
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
