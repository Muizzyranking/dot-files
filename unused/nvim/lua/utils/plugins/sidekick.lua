---@class utils.plugins.sidekick
local M = {}

M.notify = Utils.notify.create({ title = "Sidekick" })

---@param state sidekick.cli.State[]
local function kill_session(state)
  local State = require("sidekick.cli.state")
  if not state or not state.session then
    M.notify.warn("No session to kill", vim.log.levels.WARN)
    return
  end

  State.detach(state)
  local tool_name = state.tool.name
  require("sidekick.cli").close()
  if state.session.mux_session then
    Utils.run_command("tmux kill-session -t " .. vim.fn.shellescape(state.session.mux_session), {
      callback = function(_, success)
        if success then
          M.notify("Killed " .. tool_name .. " session")
        else
          M.notify.error("Failed to kill " .. tool_name .. " session")
        end
      end,
    })
  end
end

function M.kill_attached_session()
  local attached = require("sidekick.cli.state").get({ attached = true })

  if #attached == 0 then
    M.notify.warn("No active CLI session")
    return
  end

  if #attached == 1 then
    kill_session(attached[1])
    return
  end

  local choices = {}
  for _, state in ipairs(attached) do
    table.insert(choices, state.tool.name)
  end

  vim.ui.select(choices, {
    prompt = "Select session to kill:",
  }, function(choice, idx)
    if not choice then return end
    local state = attached[idx]
    kill_session(state)
  end)
end

function M.kill_session(opts)
  local Cli = require("sidekick.cli")
  local Util = require("sidekick.util")

  opts = opts or {}
  Cli.select({
    auto = true,
    filter = Util.merge(opts.filter, { started = true }),
    cb = kill_session,
  })
end

return M
