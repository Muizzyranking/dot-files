local M = {}
local git = Utils.git
local notify = Utils.notify.create({ title = "Git" })

local config = {
  float_win_opts = {
    staging = {
      height_frac = 0.8,
      width_frac = 0.6,
      style = "minimal",
      border = "rounded",
      title = " Git Status ",
      title_pos = "center",
      footer = " a: Toggle | A: All | c: Commit | p: Push | q: Quit ",
      footer_pos = "center",
    },
    commit = {
      height_frac = 0.6,
      width_frac = 0.8,
      style = "minimal",
      border = "rounded",
      title = " Commit Message ",
      title_pos = "center",
      footer = " <C-s>: Save & Commit ",
      footer_pos = "center",
    },
  },
  default_expanded = true,
  icons = { outgoing = "↑", incoming = "↓", changed = "", untracked = "?" },
}

---@type utils.git.stageSessionState
local session_state = { repos = {} }

local commit_types = {
  { type = "feat", emoji = "✨", desc = "A new feature" },
  { type = "fix", emoji = "🐛", desc = "A bug fix" },
  { type = "docs", emoji = "📝", desc = "Documentation only changes" },
  { type = "style", emoji = "💄", desc = "Code style changes" },
  { type = "refactor", emoji = "♻️", desc = "Code refactoring" },
  { type = "perf", emoji = "⚡", desc = "Performance improvements" },
  { type = "test", emoji = "✅", desc = "Adding or updating tests" },
  { type = "build", emoji = "👷", desc = "Build system or dependencies" },
  { type = "ci", emoji = "💚", desc = "CI configuration changes" },
  { type = "chore", emoji = "🔧", desc = "Other changes" },
  { type = "revert", emoji = "⏪", desc = "Revert a previous commit" },
  { type = "deps", emoji = "📦", desc = "Update dependencies" },
  { type = "init", emoji = "🎉", desc = "Initial commit" },
}

Utils.hl.add_highlights({
  MyGitStaged = { link = "String" },
  MyGitPartial = { link = "DiagnosticWarn" },
  MyGitUnstaged = { link = "DiagnosticError" },
  MyGitUntracked = { link = "Comment" },
  MyGitFolder = { link = "Directory" },
  MyGitSectionTitle = { link = "Title" },
  MyGitCommitHash = { link = "Constant" },
})

---@return string|nil

---@return string|nil
local function get_project_hash()
  local root = git.get_git_root()
  if not root then return nil end
  return vim.fn.sha256(root)
end

---@param root string
---@return utils.git.stageState
local function get_state(root)
  if not session_state.repos[root] then session_state.repos[root] = { expanded = {}, cursor = nil } end
  return session_state.repos[root]
end

local function get_draft_path()
  local hash = get_project_hash()
  if not hash then return nil end
  local cache_dir = vim.fn.stdpath("cache") .. "/commit_draft"
  vim.fn.mkdir(cache_dir, "p")
  return cache_dir .. "/" .. hash .. ".txt"
end

local function clear_draft()
  local draft_path = get_draft_path()
  if draft_path then os.remove(draft_path) end
end

---@param buf integer
local function save_draft(buf)
  if vim.b[buf].commit_success then return end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local clean_lines = {}
  for _, line in ipairs(lines) do
    if not line:match("^#") then table.insert(clean_lines, line) end
  end

  if vim.trim(table.concat(clean_lines, "\n")) == "" then
    clear_draft()
    return
  end

  local draft_path = get_draft_path()
  if draft_path then vim.fn.writefile(clean_lines, draft_path) end
end

---@param buf integer
---@return boolean loaded
local function load_draft(buf)
  local draft_path = get_draft_path()
  if draft_path and vim.fn.filereadable(draft_path) == 1 then
    local lines = vim.fn.readfile(draft_path)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    return true
  end
  return false
end

---@param root string
---@return utils.git.stageStat
local function get_repo_stats(root)
  local count_out = git.exec({ "rev-list", "--left-right", "--count", "HEAD...@{u}" }, root)
  local ahead, behind = 0, 0
  if count_out then
    local a, b = count_out:match("(%d+)%s+(%d+)")
    ahead = tonumber(a) or 0
    behind = tonumber(b) or 0
  end

  local status_out = git.exec({ "status", "--porcelain=v1", "-uall" }, root) or ""
  local changes = 0
  local untracked = 0
  for line in status_out:gmatch("[^\n]+") do
    local s = line:sub(1, 2)
    if s == "??" then
      untracked = untracked + 1
    else
      changes = changes + 1
    end
  end

  return { ahead = ahead, behind = behind, changes = changes, untracked = untracked }
end

---@param root string
---@return utils.git.File[]
local function parse_git_status(root)
  local res = git.exec({ "status", "--porcelain=v1", "-uall" }, root)
  if not res then return {} end

  local files = {} --[[ @type table<string,utils.git.File> ]]

  for line in res:gmatch("[^\n]+") do
    if line ~= "" then
      local status = line:sub(1, 2)
      local path = line:sub(4)

      if status:match("R") then
        local _, new = path:match("^(.-) %-> (.*)$")
        path = new or path
        status = "R "
      end

      path = vim.trim(path)
      if path:sub(1, 1) == '"' and path:sub(-1) == '"' then path = path:sub(2, -2) end

      local parts = vim.split(path, "/")
      local current = files
      for i, part in ipairs(parts) do
        if i == #parts then
          current[part] = { path = path, status = status, is_dir = false }
        else
          local dirpath = table.concat({ unpack(parts, 1, i) }, "/")
          if not current[part] then current[part] = { path = dirpath, is_dir = true, children = {} } end
          current = current[part].children --[[@as table<string, utils.git.File>]]
        end
      end
    end
  end

  ---@param tbl table<string, utils.git.File>
  ---@return utils.git.File[]
  local function build_tree(tbl)
    local tree = {}
    for _, item in pairs(tbl) do
      if item.is_dir then
        item.children = build_tree(item.children --[[@as table]])
      end
      table.insert(tree, item)
    end
    table.sort(tree, function(a, b)
      if a.is_dir == b.is_dir then return a.path < b.path end
      return a.is_dir
    end)
    return tree
  end

  return build_tree(files)
end

---@param root string
---@return string[]
local function get_unpushed_commits(root)
  local out = git.exec({ "log", "@{u}..HEAD", "--pretty=format:%h %s" }, root)
  if not out or out == "" then return {} end
  return vim.split(out, "\n")
end

---@param root string
---@return string[]
local function get_staged_files(root)
  local out = git.exec({ "diff", "--cached", "--name-only" }, root)
  if not out or out == "" then return {} end
  return vim.split(out, "\n")
end

---@param status string
---@return boolean
local function is_staged(status)
  return status:sub(1, 1) ~= " " and status:sub(1, 1) ~= "?"
end
---@param status string
---@return boolean
local function is_partial(status)
  return is_staged(status) and status:sub(2, 2) ~= " "
end

---Get the display letter for the status
---@param status string
---@return string
local function get_display_letter(status)
  if status == "??" then return "?" end
  -- Porcelain format: XY
  -- X = Staged, Y = Unstaged
  local x = status:sub(1, 1)
  local y = status:sub(2, 2)

  if x ~= " " and x ~= "?" then return x end -- Staged status takes priority for letter
  if y ~= " " then return y end -- Unstaged status (e.g. " M")
  return "?"
end

---@param item utils.git.File
---@return string highlight_group
local function get_file_hl(item)
  if item.is_dir then return "MyGitFolder" end
  local status = item.status
  if status == "??" then
    return "MyGitUntracked"
  elseif is_staged(status) and not is_partial(status) then
    return "MyGitStaged"
  elseif is_partial(status) then
    return "MyGitPartial"
  else
    return "MyGitUnstaged"
  end
end

---@param item utils.git.File
---@return string icon
local function get_icon(item)
  local mini_icons = require("mini.icons")
  if item.is_dir then
    return mini_icons.get("directory", item.path)
  else
    return mini_icons.get("file", item.path)
  end
end

---@param tree utils.git.File[]
---@param level integer
---@param expanded_dirs table<string, boolean>
---@return FlatNode[]
local function flatten_tree(tree, level, expanded_dirs)
  local flat = {}
  for _, item in ipairs(tree) do
    local expanded = item.is_dir and (expanded_dirs[item.path] or false)
    table.insert(flat, { item = item, expanded = expanded, level = level })
    if item.is_dir and expanded then
      local children = flatten_tree(item.children or {}, level + 1, expanded_dirs)
      vim.list_extend(flat, children)
    end
  end
  return flat
end

---@param buf integer
---@param root string
---@param tree utils.git.File[]
---@param expanded_dirs table<string, boolean>
local function render_staging_buf(buf, root, tree, expanded_dirs)
  local lines = {}
  local hl_data = {}
  local pad = "  "

  local stats = get_repo_stats(root)
  local header_str = string.format(
    "%s%s %d   %s %d   %s %d   %s %d",
    pad,
    config.icons.outgoing,
    stats.ahead,
    config.icons.incoming,
    stats.behind,
    config.icons.changed,
    stats.changes,
    config.icons.untracked,
    stats.untracked
  )

  table.insert(lines, header_str)
  table.insert(lines, "")
  table.insert(hl_data, { line = 0, start = 0, end_ = -1, group = "Comment" })

  local flat = flatten_tree(tree, 0, expanded_dirs)
  local tree_start_idx = #lines

  if #flat == 0 then
    table.insert(lines, pad .. "No changes.")
    table.insert(hl_data, { line = #lines - 1, start = 0, end_ = -1, group = "Comment" })
  end

  for i, node in ipairs(flat) do
    local prefix_str = ""
    for lvl = 1, node.level do
      local is_continuation = false
      for k = i + 1, #flat do
        local next_node = flat[k]
        if next_node.level < lvl then break end
        if next_node.level == lvl then
          is_continuation = true
          break
        end
      end
      if lvl == node.level then
        prefix_str = prefix_str .. (is_continuation and "├─" or "└─")
      else
        prefix_str = prefix_str .. (is_continuation and "│ " or "  ")
      end
    end

    local icon = get_icon(node.item)
    local name = vim.fs.basename(node.item.path)
    -- FIXED: Use improved status letter logic
    local status_mark = node.item.is_dir and "" or (get_display_letter(node.item.status) .. " ")
    local expander = node.item.is_dir and (node.expanded and "▼ " or "▶ ") or "  "

    local line_text = pad .. prefix_str .. expander .. icon .. " " .. status_mark .. name
    table.insert(lines, line_text)

    local hl_group = get_file_hl(node.item)
    -- HL Start = pad + prefix + expander
    local prefix_len = #pad + #prefix_str + #expander
    table.insert(hl_data, { line = tree_start_idx + (i - 1), start = prefix_len, end_ = -1, group = hl_group })
    table.insert(hl_data, { line = tree_start_idx + (i - 1), start = 0, end_ = prefix_len, group = "Comment" })
  end

  -- 3. UNPUSHED
  local unpushed = get_unpushed_commits(root)
  if #unpushed > 0 then
    table.insert(lines, "")
    table.insert(lines, pad .. "Unpushed Commits:")
    local title_idx = #lines - 1
    table.insert(hl_data, { line = title_idx, start = 0, end_ = -1, group = "MyGitSectionTitle" })

    for _, commit_line in ipairs(unpushed) do
      table.insert(lines, pad .. "  " .. commit_line)
      local line_idx = #lines - 1
      local hash_end = commit_line:find(" ")
      if hash_end then
        table.insert(hl_data, { line = line_idx, start = 4, end_ = 4 + hash_end, group = "MyGitCommitHash" })
      end
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  for _, hl in ipairs(hl_data) do
    ---@diagnostic disable-next-line: deprecated
    vim.api.nvim_buf_add_highlight(buf, 0, hl.group, hl.line, hl.start, hl.end_)
  end
end

-- =============================================================================
--  ACTIONS
-- =============================================================================

---@param root string
---@param item utils.git.File
local function toggle_stage(root, item)
  local args = {}
  if item.is_dir then
    -- Check if children are staged
    local fully_staged = true
    local function check(children)
      for _, child in ipairs(children) do
        if child.is_dir then
          check(child.children or {})
        else
          if not (is_staged(child.status) and not is_partial(child.status)) then
            fully_staged = false
            return
          end
        end
      end
    end
    check(item.children or {})
    args = fully_staged and { "restore", "--staged" } or { "add" }
    table.insert(args, item.path)
  else
    if is_staged(item.status) then
      args = { "restore", "--staged", item.path }
    else
      args = { "add", item.path }
    end
  end

  git.exec(args, root)
end

---@param root string
---@param tree utils.git.File[]
local function toggle_all(root, tree)
  local all_fully_staged = true
  local function check(t)
    for _, item in ipairs(t) do
      if item.is_dir then
        check(item.children or {})
      else
        if not (is_staged(item.status) and not is_partial(item.status)) then all_fully_staged = false end
      end
    end
  end
  check(tree)

  local args = all_fully_staged and { "restore", "--staged", "." } or { "add", "." }
  git.exec(args, root)
end

---@param root string
---@param buf integer
---@param refresh_fn function
local function push_commits(root, buf, refresh_fn)
  notify.info("Pushing...")
  vim.fn.jobstart({ "git", "-C", root, "push" }, {
    on_exit = function(_, code, _)
      if code == 0 then
        notify("Pushed successfully!")
        if refresh_fn then refresh_fn(true) end
      else
        notify.error("Push failed.")
      end
    end,
  })
end

-- =============================================================================
--  WINDOW MANAGEMENT
-- =============================================================================

local function compute_win_opts(opts)
  local height = math.floor(opts.height_frac * vim.o.lines)
  local width = math.floor(opts.width_frac * vim.o.columns)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  return {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = opts.style,
    border = opts.border,
    title = opts.title,
    title_pos = opts.title_pos,
    footer = opts.footer,
    footer_pos = opts.footer_pos,
  }
end

---@param win integer|nil
local function safe_close(win)
  if win and vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
end

-- =============================================================================
--  STAGING UI
-- =============================================================================

---@param tree utils.git.File[]
---@param expanded_dirs table<string, boolean>
local function set_initial_expanded(tree, expanded_dirs)
  if next(expanded_dirs) then return end
  if not config.default_expanded then return end
  local function expand(t)
    for _, item in ipairs(t) do
      if item.is_dir then
        expanded_dirs[item.path] = true
        expand(item.children or {})
      end
    end
  end
  expand(tree)
end

---@param flat FlatNode[]
---@param idx integer
---@param expanded_dirs table<string, boolean>
---@param expand boolean|nil
local function toggle_expand_state(flat, idx, expanded_dirs, expand)
  local node = flat[idx]
  if not node or not node.item.is_dir then return end
  local path = node.item.path
  if expand == nil then
    expanded_dirs[path] = not expanded_dirs[path]
  else
    expanded_dirs[path] = expand
  end
end

local function open_staging_ui()
  local root = git.get_git_root()
  if not root then
    notify.error("Not in a git repo")
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, compute_win_opts(config.float_win_opts.staging))

  local win_opts =
    { signcolumn = "no", number = false, relativenumber = false, foldcolumn = "0", cursorline = true, wrap = false }
  for k, v in pairs(win_opts) do
    vim.api.nvim_set_option_value(k, v, { win = win })
  end
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "mygitstaging", { buf = buf })

  -- Initialize State
  local state = get_state(root)
  local tree = parse_git_status(root)
  set_initial_expanded(tree, state.expanded)
  local header_offset = 2

  local function refresh(preserve_cursor)
    if not vim.api.nvim_win_is_valid(win) then return end

    local cur = { header_offset + 1, 0 }
    if preserve_cursor then
      cur = vim.api.nvim_win_get_cursor(win)
    elseif state.cursor then
      cur = state.cursor
    end

    tree = parse_git_status(root)
    render_staging_buf(buf, root, tree, state.expanded)

    local max_line = vim.api.nvim_buf_line_count(buf)
    if max_line > 0 then
      local safe_row = math.min(cur[1], max_line)
      vim.api.nvim_win_set_cursor(win, { safe_row, cur[2] })
      state.cursor = { safe_row, cur[2] }
    end
  end

  vim.b[buf].refresh = refresh
  refresh(false)

  -- Ensure Normal Mode
  vim.schedule(function()
    vim.cmd("stopinsert")
  end)

  -- Keymaps
  local function map(key, cb)
    vim.keymap.set("n", key, cb, { buffer = buf, noremap = true, silent = true })
  end

  local function get_cursor_node()
    local lnum = vim.api.nvim_win_get_cursor(win)[1]
    state.cursor = { lnum, 0 }
    if lnum <= header_offset then return nil end
    local flat = flatten_tree(tree, 0, state.expanded)
    return flat[lnum - header_offset], flat, lnum - header_offset
  end

  map("l", function()
    local node, flat, idx = get_cursor_node()
    if node then
      toggle_expand_state(flat, idx, state.expanded, true)
      refresh(true)
    end
  end)
  map("<CR>", function()
    local node, flat, idx = get_cursor_node()
    if node then
      toggle_expand_state(flat, idx, state.expanded, true)
      refresh(true)
    end
  end)
  map("h", function()
    local node, flat, idx = get_cursor_node()
    if node then
      toggle_expand_state(flat, idx, state.expanded, false)
      refresh(true)
    end
  end)
  map("a", function()
    local node = get_cursor_node()
    if node then
      toggle_stage(root, node.item)
      refresh(true)
    end
  end)
  map("A", function()
    toggle_all(root, tree)
    refresh(true)
  end)
  map("c", function()
    safe_close(win)
    M.open_commit(true)
  end)
  map("p", function()
    push_commits(root, buf, refresh)
  end)
  map("q", function()
    safe_close(win)
  end)
  map("<Esc>", function()
    safe_close(win)
  end)

  -- Save state on leave
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then state.cursor = vim.api.nvim_win_get_cursor(win) end
    end,
  })
end

-- =============================================================================
--  COMMIT UI
-- =============================================================================

---@param buf integer
---@param root string
local function render_commit_buf(buf, root)
  if not load_draft(buf) then vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" }) end

  -- Clean existing staged list
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local staged_start = nil
  for i, line in ipairs(lines) do
    if line == "# Staged files:" then
      staged_start = i - 1
      break
    end
  end
  if staged_start then vim.api.nvim_buf_set_lines(buf, staged_start, -1, false, {}) end

  -- Append new staged list
  local staged = get_staged_files(root)
  if #staged > 0 then
    local append = { "", "# Staged files:" }
    for _, file in ipairs(staged) do
      table.insert(append, "# " .. file)
    end
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, append)
  end
end

---@param buf integer
---@param from_staging boolean
---@param root string
local function perform_commit(buf, from_staging, root)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local msg = {}
  for _, line in ipairs(lines) do
    if not line:match("^#") then table.insert(msg, line) end
  end
  local msg_str = table.concat(msg, "\n")

  if vim.trim(msg_str) == "" then
    notify.warn("Empty commit message")
    return
  end

  local res = git.exec({ "commit", "-m", msg_str }, root)

  if res then
    vim.b[buf].commit_success = true
    clear_draft()
    notify("Commit successful")
    safe_close(vim.api.nvim_get_current_win())
    if from_staging then M.open_staging() end
  else
    notify.error("Commit failed")
  end
end

---@param from_staging boolean
local function open_commit_ui(from_staging)
  local root = git.get_git_root()
  if not root then
    notify.error("Not in a git repo")
    return
  end

  local staged = get_staged_files(root)
  if #staged == 0 then
    notify.warn("No staged files")
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.b[buf].commit_success = false
  local win = vim.api.nvim_open_win(buf, true, compute_win_opts(config.float_win_opts.commit))

  -- Window Options
  local win_opts = {
    signcolumn = "yes:2",
    number = false,
    relativenumber = false,
    foldcolumn = "0",
    scrolloff = 0,
    sidescrolloff = 0,
    cursorline = true,
    wrap = false,
  }
  for k, v in pairs(win_opts) do
    -- vim.api.nvim_win_set_option(win, k, v)
    vim.api.nvim_set_option_value(k, v, { win = win })
  end
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "gitcommit", { buf = buf })

  render_commit_buf(buf, root)
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  vim.cmd("startinsert")

  -- Abbrevs
  for _, ct in ipairs(commit_types) do
    vim.cmd(string.format("iabbrev <buffer> %s %s %s: ", ct.type, ct.emoji, ct.type))
  end

  local function close()
    safe_close(win)
    if from_staging then M.open_staging() end
  end

  vim.keymap.set("n", "<C-s>", function()
    perform_commit(buf, from_staging, root)
  end, { buffer = buf })
  vim.keymap.set("i", "<C-s>", function()
    perform_commit(buf, from_staging, root)
  end, { buffer = buf })
  vim.keymap.set("n", "q", close, { buffer = buf })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    callback = function()
      save_draft(buf)
    end,
  })
end

-- =============================================================================
--  PUBLIC API
-- =============================================================================

function M.open_staging()
  open_staging_ui()
end

---@param from_staging boolean|nil
function M.open_commit(from_staging)
  open_commit_ui(from_staging or false)
end

---@param opts utils.git.stageOpts
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  vim.keymap.set("n", "<leader>ks", M.open_staging)
  vim.keymap.set("n", "<leader>kc", function()
    M.open_commit(false)
  end)
end

return M
