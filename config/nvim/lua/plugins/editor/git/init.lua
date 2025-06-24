require("plugins.editor.git.keys")
local plugins = {
  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buffer)
        Utils.autocmd.on_user_event(
          "GitSignUpdate",
          vim.schedule_wrap(function()
            vim.cmd.redrawtabline()
          end)
        )

        local gs = package.loaded.gitsigns

        local function gs_visual(op)
          return function()
            return gs[op]({ vim.fn.line("."), vim.fn.line("v") })
          end
        end
        Utils.map.set_keymaps({
          {
            "]h",
            function()
              if vim.wo.diff then
                vim.cmd.normal({ "]c", bang = true })
              else
                gs.nav_hunk("next")
              end
            end,
            desc = "Next Hunk",
            icon = { icon = "󰊢 " },
          },
          {
            "[h",
            function()
              if vim.wo.diff then
                vim.cmd.normal({ "[c", bang = true })
              else
                gs.nav_hunk("prev")
              end
            end,
            desc = "Prev Hunk",
            icon = { icon = "󰊢 " },
          },
          {
            "<leader>ghs",
            gs.stage_hunk,
            icon = { icon = "󰊢 " },
          },
          {
            "<leader>ghs",
            gs_visual("stage_hunk"),
            desc = "Stage Hunk",
            icon = { icon = "󰊢 " },
            mode = { "v" },
          },
          {
            "<leader>ghr",
            gs.reset_hunk,
            desc = "Reset Hunk",
            icon = { icon = "󰜉 " },
          },
          {
            "<leader>ghr",
            gs_visual("reset_hunk"),
            desc = "Reset Hunk",
            icon = { icon = "󰜉 " },
            mode = { "v" },
          },
          {
            "<leader>ghp",
            gs.preview_hunk_inline,
            desc = "Preview Hunk Inline",
            icon = { icon = " " },
          },
          {
            "<leader>ghu",
            gs.undo_stage_hunk,
            desc = "Undo Stage Hunk",
            icon = { icon = " " },
          },
          {
            "<leader>ghu",
            gs_visual("undo_stage_hunk"),
            desc = "Undo Stage Hunk",
            icon = { icon = " " },
            mode = { "v" },
          },
          {
            "<leader>gs",
            gs.stage_buffer,
            desc = "Stage Buffer",
            icon = { icon = " ", color = "green" },
          },
          {
            "<leader>gr",
            gs.reset_buffer,
            desc = "Reset Buffer",
            icon = { icon = " " },
          },
          {
            "<leader>gB",
            function()
              gs.blame_line({ full = true })
            end,
            desc = "Blame Line",
            icon = { icon = " " },
          },
          -- {
          --   "<leader>gd",
          --   gs.diffthis,
          --   desc = "Diff this",
          --   icon = { icon = " " },
          -- },
          {
            "<leader>gD",
            function()
              gs.diffthis("~")
            end,
            desc = "Diff this ~",
            icon = { icon = " " },
          },
        }, { buffer = buffer })
      end,
    },
  },
  {
    "axkirillov/unified.nvim",
    keys = {
      {
        "<leader>gd",
        function()
          require("unified.diff").show_current()
        end,
        desc = "Unified Diff",
      },
    },
    opts = {
      signs = {
        add = "│",
        delete = "│",
        change = "│",
      },
      highlights = {
        add = "DiffAdd",
        delete = "DiffDelete",
        change = "DiffChange",
      },
      line_symbols = {
        add = "+",
        delete = "-",
        change = "~",
      },
      auto_refresh = true,
    },
  },
}
for _, plugin in ipairs(plugins) do
  plugin.cond = Utils.is_in_git_repo
end

return plugins
