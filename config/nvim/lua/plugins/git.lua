return {
  {
    "lewis6991/gitsigns.nvim",
    event = "InGitRepo",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns
        local utils = require("utils")
        utils.on_load("which-key.nvim", function()
          require("which-key").add({
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
              buffer = buffer,
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
              buffer = buffer,
              icon = { icon = "󰊢 " },
            },
            {
              "<leader>ghs",
              "<cmd>Gitsigns stage_hunk<CR>",
              desc = "Stage Hunk",
              buffer = buffer,
              icon = { icon = "󰊢 " },
              mode = { "n", "v" },
            },
            {
              "<leader>ghr",
              "<cmd>Gitsigns reset_hunk<CR>",
              desc = "Reset Hunk",
              buffer = buffer,
              icon = { icon = "󰜉 " },
              mode = { "n", "v" },
            },
            {
              "<leader>ghp",
              gs.preview_hunk_inline,
              desc = "Preview Hunk Inline",
              buffer = buffer,
              icon = { icon = " " },
            },
            {
              "<leader>ghu",
              gs.undo_stage_hunk,
              desc = "Undo Stage Hunk",
              buffer = buffer,
              icon = { icon = " " },
            },
            {
              "<leader>gs",
              gs.stage_buffer,
              desc = "Stage Buffer",
              buffer = buffer,
              icon = { icon = " ", color = "green" },
            },
            {
              "<leader>gr",
              gs.reset_buffer,
              desc = "Reset Buffer",
              buffer = buffer,
              icon = { icon = " " },
            },
            {
              "<leader>gB",
              function()
                gs.blame_line({ full = true })
              end,
              desc = "Blame Line",
              buffer = buffer,
              icon = { icon = " " },
            },
            {
              "<leader>gd",
              gs.diffthis,
              desc = "Diff this",
              buffer = buffer,
              icon = { icon = " " },
            },
            {
              "<leader>gD",
              function()
                gs.diffthis("~")
              end,
              desc = "Diff this ~",
              buffer = buffer,
              icon = { icon = " " },
            },
          })
        end)
      end,
    },
  },
}
