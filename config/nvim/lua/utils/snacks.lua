---@class utils.snacks
local M = {}

M.picker = {}
M.explorer = { actions = {} }

M.explorer.actions.new_file = {
  desc = "Overide default new file action to notify lsp after creating a file",
  action = function(picker)
    local actions = require("snacks.explorer.actions")
    local Tree = require("snacks.explorer.tree")
    Snacks.input({
      prompt = 'Add a new file or directory (directories end with a "/")',
    }, function(value)
      if not value or value:find("^%s$") then return end
      local uv = vim.uv or vim.loop
      local path = svim.fs.normalize(picker:dir() .. "/" .. value)
      local is_file = value:sub(-1) ~= "/"
      local dir = is_file and vim.fs.dirname(path) or path
      if is_file and uv.fs_stat(path) then
        Snacks.notify.warn("File already exists:\n- `" .. path .. "`")
        return
      end
      vim.fn.mkdir(dir, "p")
      if is_file then
        io.open(path, "w"):close()
        vim.schedule(function()
          Utils.lsp.new_file(path)
        end)
      end
      Tree:open(dir)
      Tree:refresh(dir)
      actions.update(picker, { target = path })
    end)
  end,
}

M.explorer.actions.trash = {
  desc = "Delete to trash",
  action = function(picker)
    if not Utils.is_executable("Trash") then
      Snacks.notify.error("Trash not found", { title = "Snacks Picker" })
      return
    end
    local actions = require("snacks.explorer.actions")
    local Tree = require("snacks.explorer.tree")
    local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
    if #paths == 0 then return end
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
}

M.explorer.actions.bookmark = {
  desc = "Toggle bookmarks with grapple",
  action = function(picker)
    if not Utils.has("grapple.nvim") then
      Snacks.notify.error("Grapple.nvim not found", { title = "Snacks Explorer" })
      return
    end
    local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
    if #paths == 0 then return end
    local Tree = require("snacks.explorer.tree")
    local actions = require("snacks.explorer.actions")
    for _, path in ipairs(paths) do
      require("grapple").toggle({ path = path })
      Tree:refresh(vim.fs.dirname(path))
    end
    actions.update(picker)
  end,
}

M.explorer.format = function(item, picker)
  local ret = require("snacks.picker.format").file(item, picker)
  local item_path = Snacks.picker.util.path(item)
  if not Utils.has("grapple.nvim") then
    local exists = require("grapple").exists({ path = item_path })
    ret[#ret + 1] = { ("%s"):format(exists and "  " or ""), "DiagnosticOk" }
  end
  return ret
end

return M
