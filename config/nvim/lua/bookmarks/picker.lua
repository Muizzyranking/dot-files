local M = {}

local config = {}

function M.setup(opts)
  config = opts
end

function M.show_marks()
  local picker = Snacks.picker.marks({
    ["local"] = true,
    global = false,
    win = {
      input = {
        keys = {
          ["<c-d>"] = { "remove_mark", mode = { "i", "n" } },
        },
      },
    },
    actions = {
      remove_mark = {
        desc = "Remove mark",
        action = function(picker, _)
          local selected = picker:selected({ fallback = true })
          if #selected > 0 then
            for _, mark in ipairs(selected) do
              vim.api.nvim_buf_del_mark(mark.buf, mark.label)
            end
            -- TODO: find way to refresh
            picker:close()
            M.show_marks()
          end
        end,
      },
    },
  })
  return picker
end

function M.show_bookmarks()
  local files = require("bookmarks.files")
  local bookmarks = files.get_bookmarks()

  if #bookmarks == 0 then
    Utils.notify.warn("No bookmarks found", { title = "Bookmarks" })
    return
  end

  -- Sort bookmarks by index
  table.sort(bookmarks, function(a, b)
    return a.index < b.index
  end)

  local items = {}
  for _, bookmark in ipairs(bookmarks) do
    table.insert(items, {
      idx = bookmark.index,
      score = bookmark.index,
      text = bookmark.display,
      path = bookmark.path,
      file = bookmark.path,
      icon = config.icons.bookmark.icon,
    })
  end

  local picker = Snacks.picker({
    title = "Bookmarked Files",
    items = items,
    layout = {
      preset = "default",
    },
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
          for _, item in ipairs(selected) do
            require("bookmarks.files").remove_bookmark(item.path)
          end
          -- HACK: to refresh the picker
          M.show_bookmarks()
          picker:close()
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
  return picker
end

M.actions = {
  bookmark_file = {
    desc = "Toggle bookmarks",
    action = function(picker)
      local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
      if #paths == 0 then
        return
      end
      local Tree = require("snacks.explorer.tree")
      local actions = require("snacks.explorer.actions")
      for _, path in ipairs(paths) do
        require("bookmarks.files").toggle_bookmark(path)
        Tree:refresh(vim.fs.dirname(path))
      end
      actions.update(picker)
    end,
  },
  explorer_delete = {
    desc = "Modify explorer_del to trigger custom user event",
    action = function(picker)
      local actions = require("snacks.explorer.actions")
      local Tree = require("snacks.explorer.tree")
      local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
      if #paths == 0 then
        return
      end
      local what = #paths == 1 and vim.fn.fnamemodify(paths[1], ":p:~:.") or #paths .. " files"
      actions.confirm("Delete " .. what .. "?", function()
        for _, path in ipairs(paths) do
          local ok, err = pcall(vim.fn.delete, path, "rf")
          if ok then
            Snacks.bufdelete({ file = path, force = true })
          else
            Snacks.notify.error("Failed to delete `" .. path .. "`:\n- " .. err)
          end
          Tree:refresh(vim.fs.dirname(path))
        end
        picker.list:set_selected()
        actions.update(picker)
        vim.api.nvim_exec_autocmds("User", {
          pattern = "FileDelete",
          data = {
            paths = paths,
          },
        })
      end)
    end,
  },
}

function M.explorer_format(item, picker)
  local ret = require("snacks.picker.format").file(item, picker)
  local itemPath = Snacks.picker.util.path(item)
  local is_bookmarked = require("bookmarks.files").is_bookmarked(itemPath)
  ret[#ret + 1] = { ("%s"):format(is_bookmarked and " " or ""), "DiagnosticOk" }
  return ret
end

return M
