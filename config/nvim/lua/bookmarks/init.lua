local M = {}

-- Default
local config = {
  root_patterns = {},
  max_bookmarks = 10,
  keymaps = {
    prefix = "<leader>m",
    set_bookmark = "b", -- <leader>mb
    list_bookmarks = "l", -- <leader>ml
    clear_bookmarks = "c",
    set_mark = "m", -- <leader>mm
    list_marks = "k", -- <leader>mk
    -- goto_bookmark = "", -- <leader>m1..9
    remove_bookmark = "d", -- <leader>md (in normal mode)
    toggle_bookmark = "t", -- <leader>mt
  },
  icons = {
    bookmark = { icon = " ", color = "blue" },
    mark = " ",
  },
}

M.get_config = function()
  return M.config
end

local files = nil
local picker = nil
local ui = nil
local marks = nil
M.config = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", config, opts or {})

  -- Setup components
  files = require("bookmarks.files")
  picker = require("bookmarks.picker")
  ui = require("bookmarks.ui")
  marks = require("bookmarks.marks")

  files.setup(M.config)
  picker.setup(M.config)
  ui.setup(M.config)
  marks.setup()
  require("bookmarks.oil").setup()

  -- Setup keymaps
  M.setup_keymaps()

  -- Setup auto commands
  M.setup_autocmds()
end

function M.setup_keymaps()
  local prefix = M.config.keymaps.prefix
  local map = function(lhs, rhs, desc)
    Utils.map.set_keymap({
      lhs,
      rhs,
      desc = desc,
      mode = "n",
      icon = M.config.icons.bookmark,
    })
  end
  local lhs = function(key)
    return prefix .. M.config.keymaps[key]
  end
  Utils.map.toggle_map({
    lhs("toggle_bookmark"),
    get_state = function()
      return files.is_bookmarked(0)
    end,
    change_state = function()
      files.toggle_bookmark(0)
    end,
    name = "bookmark",
  })

  map(lhs("set_bookmark"), function()
    files.add_bookmark(0)
  end, "Bookmark file")

  map(lhs("remove_bookmark"), function()
    files.remove_bookmark(0)
  end, "Remove file from bookmarks")

  map(lhs("list_bookmarks"), function()
    picker.show_bookmarks()
  end, "Show all bookmarks")

  Utils.map.set_keymap({
    lhs("clear_bookmarks"),
    function()
      files.clear_bookmarks()
    end,
    desc = "Clear all bookmarks",
    icon = { icon = " ", color = "red" },
  })

  vim.keymap.set("n", "]k", function()
    marks.jump_mark(nil, { direction = 1, global = false })
  end, { desc = "Jump to next local mark" })
  vim.keymap.set("n", "[k", function()
    marks.jump_mark(nil, { direction = -1, global = false })
  end, { desc = "Jump to previous local mark" })
  vim.keymap.set("n", "]K", function()
    marks.jump_mark(nil, { direction = 1, global = true })
  end, { desc = "Jump to next global mark" })
  vim.keymap.set("n", "[K", function()
    marks.jump_mark(nil, { direction = -1, global = true })
  end, { desc = "Jump to previous global mark" })
  vim.keymap.set("n", "dm", function()
    marks.delete_mark_current_line()
  end, { desc = "Delete mark on current line" })

  vim.keymap.set("n", "<leader>mk", function()
    picker.show_marks()
  end, { desc = "Show marks in current buffer" })
end

function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("Bookmarks", { clear = true })

  files.update_keymaps()
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "BookmarksChanged",
    callback = function()
      files.update_keymaps()
      pcall(function()
        require("lualine").refresh()
      end)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(event)
      files.check_deleted_file(event.buf)
    end,
  })
end

return M
