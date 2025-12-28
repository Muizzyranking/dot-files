local notify = Utils.notify.create({ title = "Sidekick" })

local function kill_session(state)
  local State = require("sidekick.cli.state")
  if not state or not state.session then
    notify.warn("No session to kill", vim.log.levels.WARN)
    return
  end

  State.detach(state)
  local tool_name = state.tool.name
  require("sidekick.cli").close()
  if state.session.mux_session then
    Utils.fn.run_command("tmux kill-session -t " .. vim.fn.shellescape(state.session.mux_session), {
      callback = function(_, success)
        if success then
          notify("Killed " .. tool_name .. " session")
        else
          notify.error("Failed to kill " .. tool_name .. " session")
        end
      end,
    })
  end
end

local function kill_attached_session()
  local attached = require("sidekick.cli.state").get({ attached = true })

  if #attached == 0 then
    notify.warn("No active CLI session")
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
    if not choice then
      return
    end
    local state = attached[idx]
    kill_session(state)
  end)
end

-- local function kill_session(opts)
--   local Cli = require("sidekick.cli")
--   local Util = require("sidekick.util")
--
--   opts = opts or {}
--   Cli.select({
--     auto = true,
--     filter = Util.merge(opts.filter, { started = true }),
--     cb = kill_session,
--   })
-- end

return {
  {
    "folke/sidekick.nvim",
    opts = {
      nes = { enabled = true },
      cli = {
        watch = true,
        win = {
          keys = {
            insertstop = { "<esc>", "stopinsert", mode = "t", desc = "enter normal mode" },
            del_word = { "<c-h>", "<c-w>", mode = { "t", "i" }, desc = "delete word" },
            c_bs = { "<c-bs>", "<c-w>", mode = { "t", "i" }, desc = "delete word" },
            c_enter = { "<c-enter>", "<c-j>", mode = { "t", "i" }, desc = "new line" },
          },
        },
        mux = { backend = "tmux", enabled = true },
      },
    },
    keys = {
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      {
        "<tab>",
        function()
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>"
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      {
        "<c-_>",
        function()
          require("sidekick.cli").toggle({ name = "opencode", focus = true })
        end,
        desc = "Sidekick Toggle",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select({ filter = { installed = true } })
        end,
        desc = "Select CLI",
      },
      {
        "<leader>ak",
        kill_attached_session,
        desc = "Kill CLI Session",
      },
      {
        "<leader>ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach a CLI Session",
      },
      {
        "<leader>at",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      local icons = {
        Error = { " ", "DiagnosticError" },
        Inactive = { " ", "MsgArea" },
        Warning = { " ", "DiagnosticWarn" },
        Normal = { Utils.icons.kinds.Copilot, "Special" },
      }
      table.insert(opts.sections.lualine_x, 2, {
        function()
          local status = require("sidekick.status").get()
          return status and vim.tbl_get(icons, status.kind, 1)
        end,
        cond = function()
          return require("sidekick.status").get() ~= nil
        end,
        color = function()
          local status = require("sidekick.status").get()
          local hl = status and (status.busy and "DiagnosticWarn" or vim.tbl_get(icons, status.kind, 2))
          return { fg = Snacks.util.color(hl) }
        end,
      })

      table.insert(opts.sections.lualine_x, 2, {
        function()
          local status = require("sidekick.status").cli()
          return " " .. (#status > 1 and #status or "")
        end,
        cond = function()
          return #require("sidekick.status").cli() > 0
        end,
        color = function()
          return { fg = Utils.hl.fg("Special") }
        end,
      })
    end,
  },
}
