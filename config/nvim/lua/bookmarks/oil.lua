local namespace = vim.api.nvim_create_namespace("oil-bookmarks")

local confg

local function add_bookmark_extmarks(buffer)
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)

  local oil_url = vim.api.nvim_buf_get_name(buffer)
  local file_url = oil_url:gsub("^oil", "file")
  if vim.fn.has("win32") == 1 then
    file_url = file_url:gsub("file:///([A-Za-z])/", "file:///%1:/")
  end
  local current_dir = vim.uri_to_fname(file_url)
  local all_bookmarks_map = require("bookmarks.files").get_project_for_path(current_dir)
  local oil = require("oil")

  for n = 1, vim.api.nvim_buf_line_count(buffer) do
    local entry = oil.get_entry_on_line(buffer, n)
    if entry and entry.name ~= ".." and entry.type == "file" then
      local full_path = current_dir .. "/" .. entry.name
      full_path = Utils.norm(full_path)
      local is_bookmarked = false

      -- Check if this file is bookmarked
      for _, bookmark in ipairs(all_bookmarks_map) do
        if bookmark.path == full_path then
          is_bookmarked = true
          break
        end
      end

      if is_bookmarked ~= false then
        vim.api.nvim_buf_set_extmark(buffer, namespace, n - 1, 0, {
          virt_text = { { " ", "DiagnosticOk" } },
          hl_mode = "combine",
          priority = 10,
        })
      end
    end
  end
end

-- Set up the plugin
local function setup(config)
  config = config or {}

  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "oil" },
    callback = function()
      local buffer = vim.api.nvim_get_current_buf()

      if vim.b[buffer].oil_bookmarks_started then
        return
      end

      vim.b[buffer].oil_bookmarks_started = true

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufEnter" }, {
        buffer = buffer,
        callback = function()
          add_bookmark_extmarks(buffer)
        end,
      })

      -- Update extmarks when content changes
      vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
        buffer = buffer,
        callback = function()
          add_bookmark_extmarks(buffer)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = { "BookmarksChanged" },
        callback = function()
          add_bookmark_extmarks(buffer)
        end,
      })
    end,
  })
end

return {
  setup = setup,
}
