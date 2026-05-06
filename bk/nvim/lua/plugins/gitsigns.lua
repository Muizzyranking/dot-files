return {
  "lewis6991/gitsigns.nvim",
  event = "LazyFile",
  cond = function()
    return Utils.fn.is_in_git_repo()
  end,
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
    },
    on_attach = function(buffer)
      local group = vim.api.nvim_create_augroup("plugins.gitsigns", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "GitSignUpdate",
        callback = vim.schedule_wrap(function()
          vim.cmd.redrawtabline()
        end),
      })
      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "diff",
        group = group,
        desc = "Set up keymap for closing gitsigns diff window",
        callback = function(e)
          vim.keymap.set("n", "q", function()
            local has_diff = vim.wo.diff
            local target_win
            if not has_diff then
              return "q"
            end

            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              local buf = vim.api.nvim_win_get_buf(win)
              local bufname = Utils.fn.get_filepath(buf)
              if bufname:find("^gitsigns://") then
                target_win = win
                break
              end
            end
            if target_win then
              vim.schedule(function()
                vim.api.nvim_win_close(target_win, true)
              end)
              return ""
            end

            return "q"
          end, { expr = true, silent = true, buffer = e.buf })
        end,
      })
      local gs = package.loaded.gitsigns

      local function gs_visual(op)
        return function()
          return gs[op]({ vim.fn.line("."), vim.fn.line("v") })
        end
      end
      -- stylua: ignore start
      Utils.map.set({
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
        },
        { "<leader>ghs", gs.stage_hunk, desc = "Stage Hunk" },
        { "<leader>ghs", gs_visual("stage_hunk"), desc = "Stage Hunk", mode = { "v" } },
        { "<leader>ghr", gs.reset_hunk, desc = "Reset Hunk", icon = { icon = "󰜉 " } },
        { "<leader>ghr", gs_visual("reset_hunk"), desc = "Reset Hunk", icon = { icon = "󰜉 " }, mode = { "v" } },
        { "<leader>ghp", gs.preview_hunk_inline, desc = "Preview Hunk Inline", icon = { icon = " " } },
        { "<leader>ghu", gs.undo_stage_hunk, desc = "Undo Stage Hunk", icon = { icon = " " } },
        { "<leader>ghu", gs_visual("undo_stage_hunk"), desc = "Undo Stage Hunk", icon = { icon = " " }, mode = { "v" } },
        { "<leader>gs", gs.stage_buffer, desc = "Stage Buffer", icon = { icon = " ", color = "green" } },
        { "<leader>gr", gs.reset_buffer, desc = "Reset Buffer", icon = { icon = " " } },
        { "<leader>gB", function() gs.blame_line({ full = true }) end, desc = "Blame Line", icon = { icon = " " } },
        { "<leader>gd", gs.diffthis, desc = "Diff this", icon = { icon = " " } },
        { "<leader>gD", function() gs.diffthis("~") end, desc = "Diff this ~", icon = { icon = " " } },
      }, { buffer = buffer, icon = { icon = "󰊢 " } })
      -- stylua: ignore end
    end,
  },
}
