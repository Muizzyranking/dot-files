local M = {}

---@class Bookmark
---@field path string Full path to the file
---@field display string Display name for the bookmark
---@field index number Numeric index (1-10)

local config = {}
local bookmarks = {}
local data_file = nil

function M.setup(opts)
  config = opts

  if config.root_patterns and #config.root_patterns > 0 then
    Utils.root.add_patterns(config.root_patterns)
  end

  data_file = vim.fn.stdpath("data") .. "/bookmarks.json"

  M.load_bookmarks()

  local group = vim.api.nvim_create_augroup("BookmarksPersistence", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.save_bookmarks()
    end,
  })

  local current_root = Utils.root.get()
  if not bookmarks[current_root] then
    bookmarks[current_root] = {}
  end
end

-- Save bookmarks to disk
function M.save_bookmarks()
  ---@type table<string, Bookmark[]>
  local cleaned_bookmarks = {}

  for project_root, project_bookmarks in pairs(bookmarks) do
    local valid_bookmarks = vim.tbl_filter(function(bookmark)
      return vim.fn.filereadable(bookmark.path) == 1
    end, project_bookmarks)

    if #valid_bookmarks > 0 then
      cleaned_bookmarks[project_root] = valid_bookmarks
    end
  end

  local data = vim.fn.json_encode(cleaned_bookmarks)
  local file = io.open(data_file, "w")
  if file then
    file:write(data)
    file:close()
  else
    Utils.notify.error("Failed to save bookmarks to " .. data_file)
  end

  bookmarks = cleaned_bookmarks
end

-- Load bookmarks from disk
function M.load_bookmarks()
  local file = io.open(data_file, "r")
  if file then
    local data = file:read("*all")
    file:close()

    if data and data ~= "" then
      local ok, loaded = pcall(vim.fn.json_decode, data)
      if ok and type(loaded) == "table" then
        bookmarks = loaded

        -- Validate loaded bookmarks
        for project_root, project_bookmarks in pairs(bookmarks) do
          bookmarks[project_root] = vim.tbl_filter(function(bookmark)
            return vim.fn.filereadable(bookmark.path) == 1
          end, project_bookmarks)
        end
      else
        Utils.notify.warn("Failed to parse bookmarks data")
        bookmarks = {}
      end
    else
      bookmarks = {}
    end
  else
    bookmarks = {}
  end
end

-- Get current project root
---@return string|nil
function M.get_project_root()
  local project_root = Utils.root.get()
  if type(project_root) == "string" then
    return project_root
  elseif type(project_root) == "table" then
    return project_root[1]
  end
end

-- Get the bookmarks for the current project
---@param path? string # Project path to get bookmarks for, defaults to current project
---@return Bookmark[] # List of valid bookmarks for the project
function M.get_bookmarks(path)
  path = path or M.get_project_root()
  M.load_bookmarks()
  if not bookmarks[path] then
    bookmarks[path] = {}
  end

  local valid_bookmarks = vim.tbl_filter(function(bookmark)
    return vim.fn.filereadable(bookmark.path) == 1
  end, bookmarks[path])

  bookmarks[path] = valid_bookmarks

  return valid_bookmarks
end

-- Check if a buffer is bookmarked
---@param buf_or_path number|string # Buffer number or file path
---@return number|boolean # Index of bookmark if found, false otherwise
function M.is_bookmarked(buf_or_path)
  local path = M.get_path_from_buf_or_path(buf_or_path or 0)
  if path == "" or path == nil then
    return false
  end

  path = vim.fn.fnamemodify(path, ":p")

  local project_bookmarks = M.get_bookmarks()
  for _, bookmark in ipairs(project_bookmarks) do
    if bookmark.path == path then
      return bookmark.index
    end
  end

  return false
end

-- Add a bookmark for the given buffer
---@param buf_or_path number|string Buffer number or file path
---@return boolean Success of operation
function M.add_bookmark(buf_or_path)
  local path = M.get_path_from_buf_or_path(buf_or_path)
  if path == "" or path == nil then
    return false
  end

  path = vim.fn.fnamemodify(path, ":p")
  local display = vim.fn.fnamemodify(path, ":t")

  local project_bookmarks = M.get_bookmarks()

  for _, bookmark in ipairs(project_bookmarks) do
    if bookmark.path == path then
      Utils.notify.info("Already bookmarked")
      return false
    end
  end

  -- Check if max bookmarks reached
  if #project_bookmarks >= config.max_bookmarks then
    Utils.notify.warn("Maximum bookmarks reached (" .. config.max_bookmarks .. ")")
    return false
  end

  -- Find next available index
  local used_indices = {}
  for _, bookmark in ipairs(project_bookmarks) do
    used_indices[bookmark.index] = true
  end

  local index = 1
  while used_indices[index] and index <= config.max_bookmarks do
    index = index + 1
  end

  if index > config.max_bookmarks then
    Utils.notify.warn("No available bookmark slots")
    return false
  end

  local new_bookmark = {
    path = path,
    display = display,
    index = index,
  }

  table.insert(project_bookmarks, new_bookmark)
  Utils.notify("Bookmarked " .. display .. " as #" .. index)

  M.save_bookmarks()

  vim.api.nvim_exec_autocmds("User", { pattern = "BookmarksChanged" })
  return true
end

-- Remove a bookmark
---@param buf_or_path number|string # Buffer number or file path
---@return boolean # Success of operation
function M.remove_bookmark(buf_or_path)
  local path = M.get_path_from_buf_or_path(buf_or_path)
  if path == "" or path == nil then
    return false
  end

  local project_bookmarks = M.get_bookmarks()
  local removed_index = nil

  -- Find and remove the bookmark
  for i, bookmark in ipairs(project_bookmarks) do
    if bookmark.path == path then
      local display = bookmark.display
      removed_index = bookmark.index
      table.remove(project_bookmarks, i)
      Utils.notify("Removed bookmark #" .. removed_index .. " (" .. display .. ")")
      break
    end
  end

  if removed_index then
    table.sort(project_bookmarks, function(a, b)
      return a.index < b.index
    end)
    for _, bookmark in ipairs(project_bookmarks) do
      if bookmark.index > removed_index then
        bookmark.index = bookmark.index - 1
      end
    end

    M.save_bookmarks()
    vim.api.nvim_exec_autocmds("User", { pattern = "BookmarksChanged" })
    return true
  end

  Utils.notify.warn("No bookmark found to remove")
  return false
end

function M.clear_bookmarks(path)
  path = path or M.get_project_root()
  if bookmarks[path] then
    bookmarks[path] = nil
  end
  M.save_bookmarks()
  Utils.notify.warn("All bookmarks cleared")
end

---@param buf_or_path number|string # Buffer number or file path
---@return boolean # Success of operation
function M.toggle_bookmark(buf_or_path)
  if M.is_bookmarked(buf_or_path) then
    return M.remove_bookmark(buf_or_path)
  else
    return M.add_bookmark(buf_or_path)
  end
end

-- Go to a bookmarked file by index
---@param index number # Bookmark index to navigate to
---@return boolean # Success of operation
function M.goto_bookmark(index)
  local project_bookmarks = M.get_bookmarks()

  for _, bookmark in ipairs(project_bookmarks) do
    if bookmark.index == index then
      -- Check if file exists
      if vim.fn.filereadable(bookmark.path) == 0 then
        Utils.notify.warn("Bookmark file no longer exists: " .. bookmark.path)
        M.remove_bookmark(bookmark.path)
        return false
      end

      vim.cmd("edit " .. vim.fn.fnameescape(bookmark.path))
      return true
    end
  end

  Utils.notify.warn("No bookmark found with index " .. index)
  return false
end

-- Check if a deleted file was bookmarked and remove it
---@param buf_or_path number # Buffer number to check
---@return boolean # True if bookmark was removed
function M.check_deleted_file(buf_or_path)
  local path = M.get_path_from_buf_or_path(buf_or_path)
  if path == "" or path == nil then
    return false
  end

  path = vim.fn.fnamemodify(path, ":p")

  -- Check if the file exists
  local exists = vim.fn.filereadable(path) == 1

  if not exists then
    -- File doesn't exist, check if it was bookmarked
    local project_bookmarks = M.get_bookmarks()
    for i, bookmark in ipairs(project_bookmarks) do
      if bookmark.path == path then
        table.remove(project_bookmarks, i)
        Utils.notify.warn("Removed bookmark for ydeleted file: " .. bookmark.display)

        -- Save bookmarks to disk
        M.save_bookmarks()

        return true
      end
    end
  end

  return false
end

-- Get project for a given path (exact match or subdirectory)
---@param path string # Path to find bookmarks for
---@return Bookmark[]|nil # Bookmarks for the path or nil if not found
function M.get_project_for_path(path)
  -- Normalize input path
  path = vim.fn.fnamemodify(path, ":p")
  path = path:gsub("/+$", "") -- Remove trailing slashes

  M.load_bookmarks()

  -- First check for exact matches
  if bookmarks[path] then
    return M.get_bookmarks(path)
  end

  -- Then check if path is a subdirectory of any project
  for project_root, _ in pairs(bookmarks) do
    if M.is_subdir(project_root, path) then
      return M.get_bookmarks(project_root)
    end
  end

  return nil
end

local function split_path(path)
  local parts = {}
  for part in path:gmatch("[^/]+") do
    table.insert(parts, part)
  end
  return parts
end

---@param parent string # Parent directory path
---@param child string # Child path to check
---@return boolean
function M.is_subdir(parent, child)
  -- Normalize paths by removing trailing slashes
  parent = parent:gsub("/+$", "")
  child = child:gsub("/+$", "")

  -- Split paths into components
  local parent_parts = split_path(parent)
  local child_parts = split_path(child)

  -- A subdirectory must have more components than its parent
  if #child_parts <= #parent_parts then
    return false
  end

  -- Compare each component of the parent with the child's corresponding component
  for i = 1, #parent_parts do
    if parent_parts[i] ~= child_parts[i] then
      return false
    end
  end

  return true
end

---@param buf_or_path number|string # Buffer number to check
---@return string|nil # True if bookmark was removed
function M.get_path_from_buf_or_path(buf_or_path)
  local path
  if type(buf_or_path) == "number" then
    path = vim.api.nvim_buf_get_name(buf_or_path)
    if path == "" then
      return nil
    end
  else
    path = buf_or_path
  end
  return path ~= "" and vim.fn.fnamemodify(path, ":p") or nil
end

function M.update_keymaps()
  -- Get current project bookmarks
  local project_bookmarks = M.get_bookmarks()

  -- Sort bookmarks by index to ensure consistency
  table.sort(project_bookmarks, function(a, b)
    return a.index < b.index
  end)

  -- Create keymaps for each bookmark
  for _, bookmark in ipairs(project_bookmarks) do
    local prefix
    if config.keymaps.goto_bookmark and config.keymaps.goto_bookmark ~= "" then
      prefix = config.keymaps.goto_bookmark
    else
      prefix = config.keymaps.prefix
    end
    local keymap = prefix .. bookmark.index
    Utils.map.set_keymap({
      keymap,
      function()
        if vim.fn.filereadable(bookmark.path) == 1 then
          vim.cmd("edit " .. vim.fn.fnameescape(bookmark.path))
        else
          vim.notify("Bookmark file no longer exists: " .. bookmark.path, vim.log.levels.WARN)
          M.remove_bookmark(bookmark.path)
        end
      end,
      desc = "Go to bookmark: " .. bookmark.display,
      silent = true,
      icon = config.icons.bookmark,
    })
  end
end

return M
