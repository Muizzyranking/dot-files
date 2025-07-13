return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      on_show = function()
        Snacks.notifier.hide()
      end,
    },
    picker = {
      sources = {
        explorer = {
          on_show = function()
            Snacks.notifier.hide()
          end,
          on_close = function() end,
          layout = {
            layout = { position = "right" },
            preset = "sidebar",
            hidden = { "input" },
            auto_hide = { "input" },
          },
          supports_live = true,
          tree = true,
          watch = true,
          diagnostics_open = false,
          git_status_open = false,
          follow_file = true,
          auto_close = false,
          jump = { close = false },
          formatters = {
            file = { filename_only = true },
            severity = { pos = "right" },
          },
          -- add icon to bookmarked files in explorer
          format = function(item, picker)
            if Utils.has("grapple.nvim") then
              return require("plugins.editor.grapple.snacks").explorer.format(item, picker)
            end
          end,
          matcher = { sort_empty = false, fuzzy = true },
          actions = {
            bookmark = require("plugins.editor.grapple.snacks").explorer.actions.bookmark,
            new_file = Utils.snacks.explorer.actions.new_file,
            trash = Utils.snacks.explorer.actions.trash,
          },
          win = {
            list = {
              keys = {
                ["b"] = "bookmark",
                ["a"] = "new_file",
                ["<c-c>"] = "",
                ["T"] = "trash",
                ["s"] = "edit_vsplit",
                ["S"] = "edit_split",
              },
            },
          },
        },
      },
    },
  },
  keys = {
    {
      "<leader>e",
      function()
        Snacks.explorer({ cwd = Utils.root() })
      end,
      desc = "File explorer",
    },
    {
      "<leader>E",
      function()
        Snacks.explorer()
      end,
      desc = "File explorer (cwd)",
    },
    {
      "<leader>fe",
      function()
        if Snacks.picker.get({ source = "explorer" })[1] ~= nil then
          Snacks.picker.get({ source = "explorer" })[1]:focus()
        else
          Snacks.explorer({ cwd = Utils.root() })
        end
      end,
      desc = "Explorer Snacks (root dir)",
    },
    {
      "<leader>fE",
      function()
        Snacks.explorer()
      end,
      desc = "Explorer Snacks (cwd)",
    },
  },
}
