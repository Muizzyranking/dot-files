---@type snacks.picker.Config
return {
  title = "FFF Live Grep",
  format = "file",
  live = true,

  ---@param opts table
  finder = function(opts, ctx)
    local file_picker = require("fff.file_picker")
    local conf = require("fff.conf")

    if not file_picker.is_initialized() then
      if not file_picker.setup() then
        Utils.notify.error("fff: Failed to initialize file picker", { title = "Snacks" })
        return {}
      end
    end

    local config = conf.get()
    local merged_config = vim.tbl_deep_extend("force", config or {}, opts or {})
    if not merged_config then
      return {}
    end

    local base_path = opts.cwd or vim.uv.cwd()
    if not base_path then
      return {}
    end

    if ctx.filter.search == "" then
      return {}
    end

    opts.grep_mode = opts.grep_mode or vim.tbl_get(merged_config, "grep", "modes") or { "plain", "regex", "fuzzy" }

    local grep = require("fff.grep")
    local grep_result = grep.search(
      ctx.filter.search,
      0,
      opts.limit or merged_config.max_results,
      ---@diagnostic disable-next-line: undefined-field
      merged_config.grep_config,
      opts.grep_mode[1] or "plain"
    )

    ---@type snacks.picker.finder.Item[]
    local items = {}
    for idx, fff_item in ipairs(grep_result.items) do
      assert(fff_item.line_number, "Expected line_number in grep result item")
      fff_item.match_ranges = fff_item.match_ranges or {}

      local pos, end_pos
      if #fff_item.match_ranges == 0 then
        pos = { fff_item.line_number, 0 }
        end_pos = nil
      else
        pos = { fff_item.line_number, fff_item.match_ranges[1][1] }
        end_pos = { fff_item.line_number, fff_item.match_ranges[1][2] }
      end

      local positions = {}
      for _, range in ipairs(fff_item.match_ranges) do
        for i = range[1] + 1, range[2] do
          positions[#positions + 1] = i
        end
      end

      ---@type snacks.picker.finder.Item
      local item = {
        idx = idx,
        cwd = base_path,
        file = fff_item.relative_path,
        line = fff_item.line_content,
        pos = pos,
        end_pos = end_pos,
        positions = positions,
        score = fff_item.total_frecency_score,
        text = ("%s:%d:%d:%s"):format(fff_item.relative_path, pos[1], pos[2], fff_item.line_content),
      }

      items[#items + 1] = item
    end

    return items
  end,

  toggles = {
    _is_grep_mode_plain = { icon = "plain", value = true },
    _is_grep_mode_regex = { icon = "regex", value = true },
    _is_grep_mode_fuzzy = { icon = "fuzzy", value = true },
  },

  ---@param picker table
  on_show = function(picker)
    local modes = picker.opts.grep_mode or { "plain", "regex", "fuzzy" }
    picker.opts._is_grep_mode_plain = modes[1] == "plain"
    picker.opts._is_grep_mode_regex = modes[1] == "regex"
    picker.opts._is_grep_mode_fuzzy = modes[1] == "fuzzy"
  end,

  actions = {
    ---@param picker table
    cycle_grep_mode = function(picker)
      local modes = picker.opts.grep_mode or { "plain", "regex", "fuzzy" }
      local first_mode = table.remove(modes, 1)
      modes[#modes + 1] = first_mode
      picker.opts.grep_mode = modes
      picker.opts._is_grep_mode_plain = modes[1] == "plain"
      picker.opts._is_grep_mode_regex = modes[1] == "regex"
      picker.opts._is_grep_mode_fuzzy = modes[1] == "fuzzy"
      picker:refresh()
    end,
  },

  win = {
    input = {
      keys = {
        ["<c-y>"] = { "cycle_grep_mode", mode = { "n", "i" }, nowait = true },
      },
    },
  },
}
