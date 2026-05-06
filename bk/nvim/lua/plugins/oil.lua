return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
    -- stylua: ignore start
      { "-", function() require("oil").open_float() end, desc = "File Browser (CWD - Oil)" },
      { "_", function() require("oil").toggle_float(Utils.root()) end, desc = "File Browser (Root - Oil)" },
      -- stylua: ignore end
    },
    opts = function()
      local detail = false
      local group = vim.api.nvim_create_augroup("oil_autocmd", { clear = true })
      vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        pattern = "oil://*",
        callback = function(event)
          vim.bo[event.buf].buflisted = false
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "OilActionsPost",
        group = group,
        callback = function(event)
          if event.data.actions.type == "move" then
            Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
          end
        end,
      })

      return {
        default_file_explorer = true,
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        columns = { "icon" },
        keymaps = {
          ["gd"] = {
            desc = "Toggle file detail view",
            callback = function()
              detail = not detail
              if detail then
                require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
              else
                require("oil").set_columns({ "icon" })
              end
            end,
          },
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open the entry in a vertical split" },
          ["<C-h>"] = { "actions.select", opts = { horizontal = true }, desc = "Open the entry in a horizontal split" },
          ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
          ["<C-p>"] = "actions.preview",
          ["q"] = "actions.close",
          ["<ESC><ESC>"] = "actions.close",
          -- ["<C-l>"] = "actions.refresh",
          ["gr"] = "actions.refresh",
          ["-"] = "actions.parent",
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory" },
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["H"] = "actions.toggle_hidden",
          ["t"] = "actions.toggle_trash",
        },
        use_default_keymaps = false,
        keymaps_help = { border = "rounded" },
        view_options = {
          natural_order = true,
          case_insensitive = false,
          sort = { { "type", "asc" }, { "name", "asc" } },
        },
        float = {
          padding = 0,
          max_width = 120,
          max_height = 32,
          border = "rounded",
          win_options = {
            winblend = 0,
          },
        },
        progress = {
          border = "rounded",
          minimized_border = "none",
          win_options = { winblend = 0 },
        },
      }
    end,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      disable_ft = { "oil" },
    },
  },
}
