local utils = require("plugins.snacks.pickers.utils")

local staged_status = {
  staged_new = true,
  staged_modified = true,
  staged_deleted = true,
  renamed = true,
}

local status_map = {
  untracked = "untracked",
  modified = "modified",
  deleted = "deleted",
  renamed = "renamed",
  staged_new = "added",
  staged_modified = "modified",
  staged_deleted = "deleted",
  ignored = "ignored",
  -- clean = "",
  -- clear = "",
  unknown = "untracked",
}

--- tweaked version of `Snacks.picker.format.file_git_status`
---@type snacks.picker.format
local function format_file_git_status(item, picker)
  local ret = {} ---@type snacks.picker.Highlight[]
  local status = item.status

  local hl = "SnacksPickerGitStatus"
  if status.unmerged then
    hl = "SnacksPickerGitStatusUnmerged"
  elseif status.staged then
    hl = "SnacksPickerGitStatusStaged"
  else
    hl = "SnacksPickerGitStatus" .. status.status:sub(1, 1):upper() .. status.status:sub(2)
  end

  local icon = picker.opts.icons.git[status.status]
  if status.staged then
    icon = picker.opts.icons.git.staged
  end

  local text_icon = status.status:sub(1, 1):upper()
  text_icon = status.status == "untracked" and "?" or status.status == "ignored" and "!" or text_icon

  ret[#ret + 1] = { icon, hl }
  ret[#ret + 1] = { " ", virtual = true }
  ret[#ret + 1] = {
    col = 0,
    virt_text = { { text_icon, hl }, { " " } },
    virt_text_pos = "right_align",
    hl_mode = "combine",
  }

  return ret
end

---@type snacks.picker.Config
return {
  title = "FFFiles",

  finder = function(opts, ctx)
    local file_picker = require("fff.file_picker")

    if not file_picker.is_initialized() then
      if not file_picker.setup() then
        Utils.notify.error("fff: Failed to initialize file picker", { title = "Snacks" })
        return {}
      end
    end

    local config = require("fff.conf").get()
    local merged_config = vim.tbl_deep_extend("force", config or {}, opts or {})
    if not merged_config then
      return {}
    end

    local base_path = opts.cwd or vim.uv.cwd()
    if not base_path then
      return {}
    end

    local current_file = utils.get_current_file(base_path)

    -- NOTE: argument order matters for the Rust FFI — wrong order = SEGFAULT
    -- search_files(query, current_file, limit, max_threads, extra)
    local fff_result = file_picker.search_files(
      ctx.filter.search,
      current_file,
      opts.limit or merged_config.max_results,
      merged_config.max_threads,
      nil
    )

    ---@type snacks.picker.finder.Item[]
    local items = {}
    for _, fff_item in ipairs(fff_result) do
      ---@type snacks.picker.finder.Item
      local item = {
        text = fff_item.name,
        file = fff_item.path,
        score = fff_item.total_frecency_score,
        -- HACK: in original snacks implementation status is a string of
        -- `git status --porcelain` output
        status = status_map[fff_item.git_status] and {
          status = status_map[fff_item.git_status],
          staged = staged_status[fff_item.git_status] or false,
          unmerged = fff_item.git_status == "unmerged",
        },
      }
      items[#items + 1] = item
    end

    return items
  end,

  format = function(item, picker)
    ---@type snacks.picker.Highlight[]
    local ret = {}

    if item.label then
      ret[#ret + 1] = { item.label, "SnacksPickerLabel" }
      ret[#ret + 1] = { " ", virtual = true }
    end

    if item.status then
      vim.list_extend(ret, format_file_git_status(item, picker))
    else
      ret[#ret + 1] = { "  ", virtual = true }
    end

    vim.list_extend(ret, require("snacks").picker.format.filename(item, picker))

    if item.line then
      require("snacks").picker.highlight.format(item, item.line, ret)
      table.insert(ret, { " " })
    end

    return ret
  end,

  formatters = {
    file = {
      filename_first = true,
    },
  },

  live = true,
}
