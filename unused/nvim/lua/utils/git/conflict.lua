---@class utils.git.conflict
local M = {}

local ns = vim.api.nvim_create_namespace("git_conflict")
local notify = Utils.notify.create({ title = "Git Conflict" })

local buffer_state = {}

local config = {
  preview = {
    enabled = true,
    float_opts = {
      border = "rounded",
      max_width = 80,
      max_height = 20,
    },
  },
  keymaps = {
    choose_ours = "mo",
    choose_theirs = "mt",
    choose_both = "mb",
    choose_base = "mB",
    choose_ours_all = "mO",
    choose_theirs_all = "mT",
    next_conflict = "]x",
    prev_conflict = "[x",
    list_conflicts = "ml",
  },
  patterns = {
    ours_start = "^<<<<<<< ",
    separator = "^=======$",
    theirs_end = "^>>>>>>> ",
    base_start = "^||||||| ",
  },
  virtual_text = {
    enabled = true,
    ours = "Current Change",
    theirs = "Incoming Change",
    base = "Base (Common Ancestor)",
  },
  navigation = {
    wrap = true,
  },
  auto_detect_on_write = true,
  auto_stage_on_resolve = false,
}

local preview_win = nil
local preview_buf = nil

local function close_preview()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then vim.api.nvim_win_close(preview_win, true) end
  if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
    vim.api.nvim_buf_delete(preview_buf, { force = true })
  end
  preview_win = nil
  preview_buf = nil
end

local function show_preview(bufnr, conflict, choice)
  close_preview()

  local lines_to_show = {}
  local title = ""

  if choice == "ours" then
    lines_to_show = conflict.ours_lines
    title = " Preview: Keep Current Change "
  elseif choice == "theirs" then
    lines_to_show = conflict.theirs_lines
    title = " Preview: Keep Incoming Change "
  elseif choice == "both" then
    lines_to_show = vim.list_extend(vim.deepcopy(conflict.ours_lines), conflict.theirs_lines)
    title = " Preview: Keep Both Changes "
  elseif choice == "base" then
    if conflict.has_base then
      lines_to_show = conflict.base_lines
      title = " Preview: Keep Base (Common Ancestor) "
    else
      notify.error("No base version available")
      return
    end
  end

  if #lines_to_show == 0 then lines_to_show = { "(empty)" } end

  preview_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines_to_show)

  vim.bo[preview_buf].modifiable = false
  vim.bo[preview_buf].bufhidden = "wipe"

  local original_ft = vim.bo[bufnr].filetype
  if original_ft ~= "" then vim.bo[preview_buf].filetype = original_ft end

  -- Calculate window size
  local opts = config.preview.float_opts
  local width = math.min(opts.max_width, vim.o.columns - 4)
  local height = math.min(opts.max_height, #lines_to_show + 2, vim.o.lines - 4)

  -- Center the window
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Open floating window
  preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = opts.border,
    title = title,
    title_pos = "center",
    style = "minimal",
    noautocmd = true,
  })

  -- Set window options
  vim.wo[preview_win].wrap = false
  vim.wo[preview_win].cursorline = true

  vim.keymap.set("n", "q", close_preview, { buffer = preview_buf, silent = true, desc = "Close conflict preview" })
  vim.keymap.set("n", "<esc>", close_preview, { buffer = preview_buf, silent = true, desc = "Close conflict preview" })

  -- Auto-close on cursor move or leaving window
  local preview_augroup = vim.api.nvim_create_augroup("git_conflict_preview", { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave", "WinLeave" }, {
    group = preview_augroup,
    buffer = bufnr,
    callback = function()
      close_preview()
      vim.api.nvim_del_augroup_by_id(preview_augroup)
    end,
    once = true,
  })
end

local function setup_highlights()
  Utils.hl.add_highlights({
    GitConflictCurrent = { link = "DiffAdd", default = true },
    GitConflictIncoming = { link = "DiffDelete", default = true },
    GitConflictMarker = { link = "DiffChange", default = true },
    GitConflictBase = { link = "DiffText", default = true },
  })
end

local function find_conflicts(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local conflicts = {}
  local current_conflict = nil
  local patterns = config.patterns

  for i, line in ipairs(lines) do
    if line:match(patterns.ours_start) then
      current_conflict = { ours_start = i, ours_lines = {} }
    elseif line:match(patterns.base_start) and current_conflict then
      current_conflict.base_start = i
      current_conflict.base_lines = {}
      current_conflict.has_base = true
    elseif line:match(patterns.separator) and current_conflict then
      current_conflict.separator = i
      current_conflict.theirs_lines = {}
    elseif line:match(patterns.theirs_end) and current_conflict then
      current_conflict.theirs_end = i
      table.insert(conflicts, current_conflict)
      current_conflict = nil
    elseif current_conflict then
      if current_conflict.separator then
        table.insert(current_conflict.theirs_lines, line)
      elseif current_conflict.base_start and not current_conflict.separator then
        table.insert(current_conflict.base_lines, line)
      else
        table.insert(current_conflict.ours_lines, line)
      end
    end
  end

  -- Add metadata to each conflict
  for i, conflict in ipairs(conflicts) do
    conflict.index = i
    conflict.total = #conflicts
  end

  return conflicts
end

local function highlight_conflicts(bufnr, conflicts)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  for _, conflict in ipairs(conflicts) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, conflict.ours_start - 1, 0, {
      end_line = conflict.ours_start,
      hl_group = "GitConflictMarker",
      hl_eol = true,
      virt_text = config.virtual_text.enabled and {
        {
          string.format(" %s (%d/%d)", config.virtual_text.ours, conflict.index, conflict.total),
          "GitConflictCurrent",
        },
      } or nil,
      virt_text_pos = "eol",
    })

    vim.api.nvim_buf_set_extmark(bufnr, ns, conflict.separator - 1, 0, {
      end_line = conflict.separator,
      hl_group = "GitConflictMarker",
      hl_eol = true,
      virt_text = config.virtual_text.enabled and { { " " .. config.virtual_text.theirs, "GitConflictIncoming" } }
        or nil,
      virt_text_pos = "eol",
    })

    vim.api.nvim_buf_set_extmark(bufnr, ns, conflict.theirs_end - 1, 0, {
      end_line = conflict.theirs_end,
      hl_group = "GitConflictMarker",
      hl_eol = true,
    })

    -- Highlight ours section
    local ours_end = conflict.has_base and conflict.base_start - 1 or conflict.separator - 1
    for i = conflict.ours_start, ours_end - 1 do
      vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, {
        end_line = i + 1,
        hl_group = "GitConflictCurrent",
        hl_eol = true,
      })
    end

    -- Highlight base section if present (diff3)
    if conflict.has_base and conflict.base_start then
      vim.api.nvim_buf_set_extmark(bufnr, ns, conflict.base_start - 1, 0, {
        end_line = conflict.base_start,
        hl_group = "GitConflictMarker",
        hl_eol = true,
        virt_text = config.virtual_text.enabled and { { " " .. config.virtual_text.base, "GitConflictBase" } } or nil,
        virt_text_pos = "eol",
      })

      for i = conflict.base_start, conflict.separator - 2 do
        vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, {
          end_line = i + 1,
          hl_group = "GitConflictBase",
          hl_eol = true,
        })
      end
    end

    for i = conflict.separator, conflict.theirs_end - 2 do
      vim.api.nvim_buf_set_extmark(bufnr, ns, i, 0, {
        end_line = i + 1,
        hl_group = "GitConflictIncoming",
        hl_eol = true,
      })
    end
  end
end

function M.list_conflict_files()
  -- Get git root
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    notify.error("Not in a git repository")
    return
  end

  -- Get files with conflicts (unmerged files)
  local files = vim.fn.systemlist("git diff --name-only --diff-filter=U")
  if vim.v.shell_error ~= 0 or #files == 0 then
    notify.info("No files with conflicts")
    return
  end

  local items = {}
  for _, file in ipairs(files) do
    local full_path = git_root .. "/" .. file
    local bufnr = vim.fn.bufnr(full_path)

    -- Count conflicts if buffer is loaded
    local conflict_count = 0
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then conflict_count = #find_conflicts(bufnr) end

    table.insert(items, {
      text = file,
      file = full_path,
      conflicts = conflict_count,
    })
  end

  Snacks.picker.pick({
    source = "conflict-files",
    title = string.format("Files with Conflicts (%d)", #items),
    items = items,
    confirm = function(picker, item)
      picker:close()
      vim.cmd("edit " .. vim.fn.fnameescape(item.file))
    end,
  })
end

-- Mark buffer as having conflicts
local function mark_as_conflict_buffer(bufnr)
  bufnr = Utils.ensure_buf(bufnr)

  -- Skip if already marked
  if vim.b[bufnr].git_conflict then return end

  local keymaps = config.keymaps
  local keys = {
    {
      "<leader>gcp",
      function()
        vim.ui.select({ "ours", "theirs", "both", "base" }, {
          prompt = "Preview which version?",
          format_item = function(item)
            local labels = {
              ours = "Current Change",
              theirs = "Incoming Change",
              both = "Both Changes",
              base = "Base (Common Ancestor)",
            }
            return labels[item]
          end,
        }, function(choice)
          if choice then M.preview(choice) end
        end)
      end,
      desc = "Preview conflict resolution",
    },

    {
      "<leader>gcf",
      function()
        M.list_conflict_files()
      end,
      desc = "Choose 'ours' version for current conflict",
    },
    {
      keymaps.choose_ours,
      function()
        M.choose("ours")
      end,
      desc = "Choose 'ours' version for current conflict",
    },
    {
      keymaps.choose_theirs,
      function()
        M.choose("theirs")
      end,
      desc = "Choose 'theirs' version for current conflict",
    },
    {
      keymaps.choose_both,
      function()
        M.choose("both")
      end,
      desc = "Keep both versions",
    },
    {
      keymaps.choose_base,
      function()
        M.choose("base")
      end,
      desc = "Choose base (common ancestor) version",
    },
    {
      keymaps.choose_ours_all,
      function()
        M.choose_all("ours")
      end,
      desc = "Choose 'ours' version for all conflicts",
    },
    {
      keymaps.choose_theirs_all,
      function()
        M.choose_all("theirs")
      end,
      desc = "Choose 'theirs' version for all conflicts",
    },
    {
      keymaps.next_conflict,
      M.next_conflict,
      desc = "Go to next conflict",
    },
    {
      keymaps.prev_conflict,
      M.prev_conflict,
      desc = "Go to previous conflict",
    },
    {
      keymaps.list_conflicts,
      M.list_conflicts,
      desc = "List all conflicts",
    },
  }

  -- Store original state
  buffer_state[bufnr] = {
    diagnostics_enabled = vim.diagnostic.is_enabled({ bufnr = bufnr }),
    autoformat = vim.b[bufnr].autoformat,
    keymaps = keymaps,
    keys = keys,
  }

  -- Disable diagnostics and autoformat
  vim.diagnostic.enable(false, { bufnr = bufnr })
  vim.b[bufnr].autoformat = false
  vim.b[bufnr].git_conflict = true

  Utils.map.set(keys, { buffer = bufnr, icon = { icon = "", color = "orange" } })

  local conflicts = find_conflicts(bufnr)
  highlight_conflicts(bufnr, conflicts)

  notify.warn(string.format("Git conflicts detected: %d conflict(s)", #conflicts))
end

local function mark_as_resolved(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not buffer_state[bufnr] then return end

  if buffer_state[bufnr].diagnostics_enabled then vim.diagnostic.enable(true, { bufnr = bufnr }) end

  -- Restore autoformat
  vim.b[bufnr].autoformat = buffer_state[bufnr].autoformat
  vim.b[bufnr].git_conflict = false

  -- Clear highlights
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local keys = buffer_state[bufnr].keys
  Utils.map.del(keys, { buffer = bufnr, icon = { icon = "", color = "orange" } })
  buffer_state[bufnr] = nil

  vim.api.nvim_exec_autocmds("BufEnter", { buffer = bufnr })

  notify.info("All conflicts resolved!")

  -- Auto-stage if configured
  if config.auto_stage_on_resolve then
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    if filepath ~= "" then
      vim.system({ "git", "add", filepath }, { text = true }, function(obj)
        if obj.code == 0 then
          vim.schedule(function()
            notify.info("File staged automatically")
          end)
        end
      end)
    end
  end
end

local function find_conflict_at_cursor(bufnr, cursor_line)
  local conflicts = find_conflicts(bufnr)

  for _, conflict in ipairs(conflicts) do
    if cursor_line >= conflict.ours_start and cursor_line <= conflict.theirs_end then return conflict end
  end

  return nil
end

-- Resolve a single conflict
local function resolve_conflict(bufnr, conflict, choice)
  local lines_to_keep = {}

  if choice == "ours" then
    lines_to_keep = conflict.ours_lines
  elseif choice == "theirs" then
    lines_to_keep = conflict.theirs_lines
  elseif choice == "both" then
    -- Keep ours first, then theirs
    lines_to_keep = vim.list_extend(vim.deepcopy(conflict.ours_lines), conflict.theirs_lines)
  elseif choice == "base" then
    if conflict.has_base then
      lines_to_keep = conflict.base_lines
    else
      notify.error("No base version available (not using diff3)")
      return
    end
  else
    notify.error("Invalid choice: " .. tostring(choice))
    return
  end

  -- Save cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local was_in_conflict = cursor_pos[1] >= conflict.ours_start and cursor_pos[1] <= conflict.theirs_end

  -- Replace the entire conflict region with chosen lines
  vim.api.nvim_buf_set_lines(bufnr, conflict.ours_start - 1, conflict.theirs_end, false, lines_to_keep)

  -- Restore cursor intelligently
  if was_in_conflict then
    local new_line = math.min(conflict.ours_start + #lines_to_keep - 1, vim.api.nvim_buf_line_count(bufnr))
    vim.api.nvim_win_set_cursor(0, { new_line, cursor_pos[2] })
  end

  -- Check if all conflicts are resolved (synchronously to avoid race conditions)
  local remaining = find_conflicts(bufnr)
  if #remaining == 0 then
    mark_as_resolved(bufnr)
  else
    highlight_conflicts(bufnr, remaining)
  end
end

function M.preview(choice)
  local valid_strategies = { "ours", "theirs", "both", "base" }
  if not vim.tbl_contains(valid_strategies, choice) then error("Invalid strategy: " .. tostring(choice)) end

  if not config.preview.enabled then
    notify.warn("Preview is disabled in config")
    return
  end

  local bufnr = Utils.ensure_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local conflict = find_conflict_at_cursor(bufnr, cursor_line)

  if not conflict then
    notify.warn("No conflict at cursor")
    return
  end

  show_preview(bufnr, conflict, choice)
end

function M.choose(strategy)
  local valid_strategies = { "ours", "theirs", "both", "base" }
  if not vim.tbl_contains(valid_strategies, strategy) then
    error("Invalid strategy: " .. tostring(strategy) .. ". Must be one of: " .. table.concat(valid_strategies, ", "))
  end

  local bufnr = Utils.ensure_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local conflict = find_conflict_at_cursor(bufnr, cursor_line)

  if not conflict then
    notify.warn("No conflict at cursor")
    return
  end
  close_preview()
  resolve_conflict(bufnr, conflict, strategy)
end

function M.choose_all(strategy)
  local valid_strategies = { "ours", "theirs", "both", "base" }
  if not vim.tbl_contains(valid_strategies, strategy) then
    error("Invalid strategy: " .. tostring(strategy) .. ". Must be one of: " .. table.concat(valid_strategies, ", "))
  end

  local bufnr = Utils.ensure_buf()
  local conflicts = find_conflicts(bufnr)

  if #conflicts == 0 then
    notify.info("No conflicts to resolve")
    return
  end

  -- Resolve in reverse order to maintain line numbers
  for i = #conflicts, 1, -1 do
    resolve_conflict(bufnr, conflicts[i], strategy)
  end
end

function M.next_conflict()
  local bufnr = Utils.ensure_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local conflicts = find_conflicts(bufnr)

  if #conflicts == 0 then
    notify.info("No conflicts in buffer")
    return
  end

  -- Find next conflict after cursor
  for _, conflict in ipairs(conflicts) do
    if conflict.ours_start > cursor_line then
      vim.api.nvim_win_set_cursor(0, { conflict.ours_start, 0 })
      notify.info(string.format("Conflict %d/%d", conflict.index, conflict.total))
      return
    end
  end

  -- Wrap to first conflict if enabled
  if config.navigation.wrap and #conflicts > 0 then
    vim.api.nvim_win_set_cursor(0, { conflicts[1].ours_start, 0 })
    notify.info(string.format("Wrapped to first conflict (1/%d)", #conflicts))
  else
    notify.info("No more conflicts")
  end
end

function M.prev_conflict()
  local bufnr = Utils.ensure_buf()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local conflicts = find_conflicts(bufnr)

  if #conflicts == 0 then
    notify.info("No conflicts in buffer")
    return
  end

  -- Find previous conflict before cursor (iterate in reverse)
  for i = #conflicts, 1, -1 do
    if conflicts[i].ours_start < cursor_line then
      vim.api.nvim_win_set_cursor(0, { conflicts[i].ours_start, 0 })
      notify.info(string.format("Conflict %d/%d", conflicts[i].index, conflicts[i].total))
      return
    end
  end

  -- Wrap to last conflict if enabled
  if config.navigation.wrap and #conflicts > 0 then
    local last = conflicts[#conflicts]
    vim.api.nvim_win_set_cursor(0, { last.ours_start, 0 })
    notify.info(string.format("Wrapped to last conflict (%d/%d)", last.index, last.total))
  else
    notify.info("No previous conflicts")
  end
end

function M.list_conflicts()
  local bufnr = Utils.ensure_buf()
  local conflicts = find_conflicts(bufnr)

  if #conflicts == 0 then
    notify.info("No conflicts in buffer")
    return
  end

  local items = {}
  for _, conflict in ipairs(conflicts) do
    local preview_line = vim.api.nvim_buf_get_lines(bufnr, conflict.ours_start - 1, conflict.ours_start, false)[1] or ""
    -- Remove the conflict marker for cleaner display
    preview_line = preview_line:gsub("^<<<<<<< ", "")
    table.insert(
      items,
      string.format(
        "Conflict %d/%d (line %d): %s",
        conflict.index,
        conflict.total,
        conflict.ours_start,
        preview_line:sub(1, 50)
      )
    )
  end

  vim.ui.select(items, {
    prompt = "Jump to conflict:",
    format_item = function(item)
      return item
    end,
  }, function(_, idx)
    if idx then
      vim.api.nvim_win_set_cursor(0, { conflicts[idx].ours_start, 0 })
      notify.info(string.format("Jumped to conflict %d/%d", conflicts[idx].index, conflicts[idx].total))
    end
  end)
end

-- Get conflict count for statusline integration
function M.get_conflict_count(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.b[bufnr].git_conflict then return 0 end

  local conflicts = find_conflicts(bufnr)
  return #conflicts
end

-- Get current conflict info for statusline
function M.get_current_conflict_info(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.b[bufnr].git_conflict then return nil end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local conflict = find_conflict_at_cursor(bufnr, cursor_line)

  if conflict then return {
    index = conflict.index,
    total = conflict.total,
  } end

  return nil
end

function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend("force", config, opts)
  setup_highlights()

  local events = { "BufReadPost", "BufNewFile" }
  if config.auto_detect_on_write then table.insert(events, "BufWritePost") end

  Utils.autocmd(events, {
    group = "git_conflict_detect",
    callback = function(args)
      local bufnr = args.buf

      if args.event == "BufWritePost" and vim.b[bufnr].git_conflict then return end

      local conflicts = find_conflicts(bufnr)

      if #conflicts > 0 then
        mark_as_conflict_buffer(bufnr)
      elseif vim.b[bufnr].git_conflict then
        mark_as_resolved(bufnr)
      end
    end,
  })
end

return M
