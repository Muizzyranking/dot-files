return {
  {
    "akinsho/bufferline.nvim",
    event = { "VeryLazy" },
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete buffers to the right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete buffers to the left" },
      { "<leader>bc", "<Cmd>BufferLinePick<CR>", desc = "Choose a buffer" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    },
    opts = {
      options = {
        separator_style = "",
        close_command = function(n)
          Snacks.bufdelete.delete(n)
        end,

        right_mouse_command = function(n)
          Snacks.bufdelete.delete(n)
        end,

        diagnostics = "nvim_lsp",
        always_show_bufferline = true,
        diagnostics_indicator = function(_, _, diag)
          local icons = Utils.icons.diagnostics
          local ret = (diag.error and icons.Error .. diag.error .. " " or "")
            .. (diag.warning and icons.Warn .. diag.warning or "")
          return vim.trim(ret)
        end,
        offsets = {
          -- {
          --   filetype = "neo-tree",
          --   text = "Neo-tree",
          --   highlight = "Directory",
          --   text_align = "left",
          -- },
        },
      },
    },
    config = function(_, opts)
      Utils.on_load("which-key.nvim", function()
        require("which-key").add({
          { "<leader>bl", icon = { icon = "󰛌 ", color = "red" } },
          { "<leader>br", icon = { icon = "󰛌 ", color = "red" } },
          { "<leader>bP", icon = { icon = "󰛌 ", color = "red" } },
          { "<leader>bp", icon = { icon = " ", color = "red" } },
          { "<leader>bc", icon = { icon = " ", color = "red" } },
        })
      end)
      require("bufferline").setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd("BufAdd", {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },
}
