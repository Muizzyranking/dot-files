local notify = Utils.notify.create({ title = "Sidekick" })

local function kill_session(state)
  if not state or not state.session then
    notify.warn("No session to kill", vim.log.levels.WARN)
    return
  end

  local tool_name = state.tool.name
  require("sidekick.cli").close()

  if state.session.mux_session then
    Utils.run_command("tmux kill-session -t " .. vim.fn.shellescape(state.session.mux_session), {
      callback = function(_, success)
        if success then
          notify("Killed " .. tool_name .. " session")
        else
          notify.error("Failed to kill " .. tool_name .. " session")
        end
      end,
    })
  else
    require("sidekick.cli.state").detach(state)
    notify("Closed " .. tool_name .. " session")
  end
end

return {
  {
    "folke/sidekick.nvim",
    opts = {
      nes = { enabled = false },
      cli = {
        watch = true,
        win = {
          keys = {
            insertstop = { "<esc>", "stopinsert", mode = "t", desc = "enter normal mode" },
            del_word = {
              "<c-h>",
              function()
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>", true, false, true), "i", false)
              end,
              mode = { "t", "i" },
              desc = "delete word",
            },
            c_enter = {
              "<c-enter>",
              function()
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-j>", true, false, true), "i", false)
              end,
              mode = { "t", "i" },
              desc = "new line",
            },
          },
          nav = function(dir)
            -- \x17 is the hex code for Ctrl-W
            -- i override default <c-w>hjkl behavior to enable smart navigation
            -- see lua/utils/smart_nav.lua
            vim.cmd("normal! \x17" .. dir)
          end,
        },
        mux = {
          backend = "tmux",
          enabled = true,
        },
      },
    },
    keys = {
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      {
        "<c-_>",
        function()
          require("sidekick.cli").toggle({ name = "gemini", focus = true })
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
        function()
          local attached = require("sidekick.cli.state").get({ attached = true })

          if #attached == 0 then
            notify.warn("No active CLI session")
            return
          end

          if #attached > 1 then
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
          else
            kill_session(attached[1])
          end
        end,
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
      table.insert(opts.sections.lualine_x, 2, {
        function()
          local status = require("sidekick.status").cli()
          return " " .. (#status > 1 and #status or "")
        end,
        cond = function()
          return #require("sidekick.status").cli() > 0
        end,
        color = function()
          return { fg = Utils.lualine.fg("Special") }
        end,
      })
    end,
  },
}
