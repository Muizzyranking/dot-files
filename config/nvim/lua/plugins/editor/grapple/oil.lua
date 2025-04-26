local namespace = vim.api.nvim_create_namespace("oil-bookmarks")
local function add_bookmark_extmarks(buffer)
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)

  local oil_url = vim.api.nvim_buf_get_name(buffer)
  local file_url = oil_url:gsub("^oil", "file")
  if vim.fn.has("win32") == 1 then
    file_url = file_url:gsub("file:///([A-Za-z])/", "file:///%1:/")
  end
  local current_dir = vim.uri_to_fname(file_url)
  local oil = require("oil")

  for n = 1, vim.api.nvim_buf_line_count(buffer) do
    local entry = oil.get_entry_on_line(buffer, n)
    if entry and entry.name ~= ".." and entry.type == "file" then
      local full_path = current_dir .. "/" .. entry.name
      full_path = Utils.norm(full_path)
      local exists = require("grapple").exists({ path = full_path })
      if exists then
        vim.api.nvim_buf_set_extmark(buffer, namespace, n - 1, 0, {
          virt_text = { { " ", "diagnosticok" } },
          hl_mode = "combine",
          priority = 10,
        })
      end
    end
  end
end
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
  end,
})
