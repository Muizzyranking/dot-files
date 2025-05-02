local M = {}
M.picker = {}
M.explorer = {}

function M.picker.show_bookmarks()
  if not Utils.has("snacks.nvim") then
    return
  end
  return Snacks.picker({
    title = "Bookmarked Files",
    layout = {
      preset = "default",
    },
    finder = function()
      local bookmarks = require("grapple").tags()
      local items = {}
      for _, bookmark in ipairs(bookmarks) do
        table.insert(items, {
          path = bookmark.path,
          file = bookmark.path,
          icon = " ",
          pos = bookmark.cursor and { bookmark.cursor[1], bookmark.cursor[2] } or nil,
        })
      end
      return items
    end,
    format = function(item, picker)
      local ret = {}
      ret[#ret + 1] = { string.format("#%d ", item.idx), "SnacksPickerLabel" }
      ret[#ret + 1] = { item.icon .. " ", "DiagnosticOk" }
      local format = require("snacks").picker.format.filename(item, picker)
      ret = vim.list_extend(ret, format)
      return ret
    end,
    win = {
      input = {
        keys = {
          ["<c-d>"] = { "remove", mode = { "i", "n" } },
          ["<c-v>"] = { "open_vsplit", mode = { "i", "n" } },
          ["<c-s>"] = { "open_split", mode = { "i", "n" } },
          ["<cr>"] = { "confirm", mode = { "i", "n" } },
          ["<c-c>"] = { "close", mode = { "i", "n" } },
        },
      },
    },
    actions = {
      confirm = {
        desc = "Open bookmarked file",
        action = function(picker, _)
          picker:close()
          local selected = picker:selected({ fallback = true })
          if #selected > 0 then
            for i, item in ipairs(selected) do
              if i == 1 then
                vim.cmd("edit " .. vim.fn.fnameescape(item.path))
                vim.cmd("normal! zz")
              else
                vim.cmd("badd " .. vim.fn.fnameescape(item.path))
              end
            end
          end
        end,
      },
      remove = {
        desc = "Remove bookmark",
        action = function(picker, _)
          local selected = picker:selected({ fallback = true })
          local cur_idx
          for _, item in ipairs(selected) do
            cur_idx = item.idx
            require("grapple").untag({ path = item.path })
          end
          picker:find({
            on_done = function()
              if picker:count() == 0 then
                picker:close()
              else
                local nr_items = #picker:items()
                picker.list:view(math.min(cur_idx, nr_items))
              end
            end,
            refresh = true,
          })
        end,
      },
      open_vsplit = {
        desc = "Open in vertical split",
        action = function(picker, item)
          picker:close()
          vim.cmd("vsplit " .. vim.fn.fnameescape(item.path))
        end,
      },
      open_split = {
        desc = "Open in horizontal split",
        action = function(picker, item)
          picker:close()
          vim.cmd("split " .. vim.fn.fnameescape(item.path))
        end,
      },
    },
  })
end

M.picker.actions = {
  bookmark = {
    desc = "Add bookmarks",
    action = function(picker, _)
      local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
      if #paths == 0 then
        return
      end
      for _, path in ipairs(paths) do
        require("grapple").tag({ path = path })
      end
    end,
  },
}

M.explorer.format = function(item, picker)
  local ret = require("snacks.picker.format").file(item, picker)
  local item_path = Snacks.picker.util.path(item)
  local exists = require("grapple").exists({ path = item_path })
  ret[#ret + 1] = { ("%s"):format(exists and "  " or ""), "DiagnosticOk" }
  return ret
end

M.explorer.actions = {
  bookmark = {
    desc = "Toggle bookmarks",
    action = function(picker)
      local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
      if #paths == 0 then
        return
      end
      local Tree = require("snacks.explorer.tree")
      local actions = require("snacks.explorer.actions")
      for _, path in ipairs(paths) do
        require("grapple").toggle({ path = path })
        Tree:refresh(vim.fs.dirname(path))
      end
      actions.update(picker)
    end,
  },
}

return M
