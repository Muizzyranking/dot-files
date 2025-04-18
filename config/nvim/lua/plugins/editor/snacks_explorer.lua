return {
  "folke/snacks.nvim",
  opts = {
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
          format = require("bookmarks.picker").explorer_format,
          matcher = { sort_empty = false, fuzzy = true },
          actions = {
            bookmark = require("bookmarks.picker").actions.bookmark_file,
            trash = {
              desc = "Move to trash",
              action = function(picker)
                if not Utils.is_executable("Trash") then
                  Snacks.notify.errror("Trash not found", { title = "Snacks Picker" })
                  return
                end
                local actions = require("snacks.explorer.actions")
                local Tree = require("snacks.explorer.tree")
                local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
                if #paths == 0 then
                  return
                end
                local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ":p:~:.") or #paths .. " files"
                actions.confirm("Trash " .. what .. "?", function()
                  for _, path in ipairs(paths) do
                    local ok, err = pcall(vim.api.nvim_command, "silent !trash " .. path)
                    if ok then
                      Snacks.bufdelete({ file = path, force = true })
                    else
                      Snacks.notify.error("Failed to trash `" .. path .. "`:\n- " .. err, { title = "Snacks Picker" })
                    end
                    Tree:refresh(vim.fs.dirname(path))
                  end
                  picker.list:set_selected()
                  actions.update(picker)
                end)
              end,
            },
          },
          win = {
            list = {
              keys = {
                ["b"] = "bookmark",
                ["<c-c>"] = "",
                ["T"] = "trash",
                ["s"] = "edit_vsplit",
                ["S"] = "edit_split",
              },
              wo = {
                cursorline = false,
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
