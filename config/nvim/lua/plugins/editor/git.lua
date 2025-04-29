return {
  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    cond = Utils.is_in_git_repo,
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buffer)
        -- easly close diffview with q
        vim.keymap.set("n", "q", function()
          local has_diff = vim.wo.diff
          local target_win

          if not has_diff then
            return "q"
          end

          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            local bufname = Utils.get_filename(buf)
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
        end, { expr = true, silent = true })

        local gs = package.loaded.gitsigns
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
            "<cmd>Gitsigns stage_hunk<CR>",
            desc = "Stage Hunk",
            icon = { icon = "󰊢 " },
            mode = { "n", "v" },
          },
          {
            "<leader>ghr",
            "<cmd>Gitsigns reset_hunk<CR>",
            desc = "Reset Hunk",
            icon = { icon = "󰜉 " },
            mode = { "n", "v" },
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
          {
            "<leader>gd",
            gs.diffthis,
            desc = "Diff this",
            icon = { icon = " " },
          },
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
}
