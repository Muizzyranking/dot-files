local notifier = {
  timeout = 3000,
  width = { min = 40, max = 0.4 },
  height = { min = 1, max = 0.6 },
  margin = { top = 0, right = 1, bottom = 0 },
  padding = true,
  sort = { "level", "added" },
  level = vim.log.levels.TRACE,
  icons = {
    error = " ",
    warn = " ",
    info = " ",
    debug = " ",
    trace = " ",
  },
  keep = function(notif)
    return vim.fn.getcmdpos() > 0
  end,
  style = "compact",
  top_down = false,
  date_format = "%R",
  ---@type string|boolean
  more_format = " ↓ %d lines ",
  refresh = 50,
}
local indent = {
  indent = {
    enabled = true,
    char = "│",
    blank = " ",
    only_scope = false,
    only_current = false,
    hl = "SnacksIndent",
  },
  animate = {
    enabled = true,
    style = "out",
    easing = "linear",
    duration = {
      step = 20,
      total = 500,
    },
  },
  scope = {
    enabled = true,
    char = "│",
    underline = false,
    only_current = false,
    hl = "SnacksIndentScope",
  },
  chunk = {
    enabled = false,
    only_current = true,
    hl = "SnacksIndentChunk",
    char = {
      -- corner_top = "┌",
      -- corner_bottom = "└",
      corner_top = "╭",
      corner_bottom = "╰",
      horizontal = "─",
      vertical = "│",
      arrow = ">",
    },
  },
  blank = {
    char = " ",
    hl = "SnacksIndentBlank",
  },
  filter = function(buf)
    return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ""
  end,
  priority = 200,
}
local explorer = {
  on_show = function()
    Snacks.notifier.hide()
  end,
  on_close = function() end,
  layout = {
    layout = { position = "right" },
    preset = "sidebar",
    hidden = { "input" },
    auto_hide = { "input" },
  },
  include = { "*.zsh*", ".env" },
  -- exclude = { "node_modules", "venv", ".venv" },
  supports_live = true,
  tree = true,
  watch = true,
  diagnostics_open = false,
  git_status_open = false,
  follow_file = true,
  auto_close = false,
  jump = { close = false },
  formatters = {
    file = { filename_only = true },
    severity = { pos = "right" },
  },
  -- add icon to bookmarked files in explorer
  matcher = { sort_empty = false, fuzzy = true },
  actions = {},
  win = {
    list = {
      keys = {
        ["<c-c>"] = "",
        ["s"] = "edit_vsplit",
        ["S"] = "edit_split",
      },
    },
  },
}
local dashboard = {
  preset = {
    keys = {
      -- stylua: ignore start
			{ icon = " ", key = "n", desc = "New File", action = ":lua vim.cmd('enew')" },
			{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files({ cwd = Utils.root() })" },
			{ icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep() " },
			{ icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
			{
				icon = " ",
				key = "R",
				desc = "Recent Files (cwd)",
				action = ":lua Snacks.picker.recent({ filter = { cwd = true }, title = 'Recent Files (cwd)' })",
			},
			{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
			{ icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
			{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
      -- stylua: ignore end
    },
  },
  sections = {
    { section = "header" },
    { section = "keys", gap = 1, padding = 1 },
    { section = "startup" },
  },
}
local layouts = {
  drop = {
    layout = {
      preview = false,
      backdrop = false,
      width = 0.4,
      min_width = 80,
      height = 0.6,
      border = "none",
      box = "vertical",
      { win = "preview", title = "{preview}", height = 0.4, border = "rounded" },
      {
        box = "vertical",
        border = "rounded",
        title = "{title} {live} {flags}",
        title_pos = "center",
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
    },
  },
  code = {
    preview = false,
    layout = {
      backdrop = false,
      row = math.floor((vim.o.lines - (math.floor(vim.o.lines * 0.8))) / 2),
      width = 0.4,
      min_width = 80,
      height = 0.4,
      border = "none",
      box = "vertical",
      {
        win = "input",
        height = 1,
        border = "rounded",
        title = "{title} {live} {flags}",
        title_pos = "center",
      },
      { win = "list", border = "hpad" },
      { win = "preview", title = "{preview}", border = "rounded" },
    },
  },
}
local picker = {
  prompt = " ",
  ui_select = true,
  sources = {
    explorer = explorer,
    files = {
      exclude = { ".git", ".cache", "node_modules", "venv", ".venv", ".pytest_cache" },
      actions = {},
    },
    buffers = {
      sort_lastused = true,
      hidden = false,
      ignore_filetype = {},
      win = {
        input = {
          keys = { ["dd"] = "bufdelete", ["<c-x>"] = { "bufdelete", mode = { "n", "i" } } },
        },
        list = { keys = { ["dd"] = "bufdelete" } },
      },
      layout = { preset = "drop", preview = false },
    },
  },
  focus = "input",
  matcher = {
    fuzzy = true,
    frecency = true,
    history_bonus = true,
  },
  jump = { reuse_win = false, match = false },
  layouts = layouts,
  actions = {},
  win = {
    input = {
      keys = { ["<C-h>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" } },
      b = { completion = false },
    },
    list = { keys = {} },
  },
}
return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 2000,
  opts = {
    explorer = {
      on_show = function()
        Snacks.notifier.hide()
      end,
    },
    input = { enabled = true },
    indent = indent,
    dashboard = dashboard,
    picker = picker,
    notifier = notifier,
    bigfile = { enabled = true },
    image = { enabled = false },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    scroll = { enabled = true },
    lazygit = {
      win = {
        bo = { filetype = "lazygit" },
        keys = { ["<C-h>"] = { "<c-s-w>", mode = { "i", "t" }, expr = true, desc = "delete word" } },
      },
      config = {
        git = { overrideGpg = true },
        promptToReturnFromSubprocess = false,
      },
    },
    styles = { input = { keys = { i_c_h = { "<c-h>", "<c-s-w>", mode = "i", expr = true } } } },
  },
  keys = {
    -- stylua: ignore start
    { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    { "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    {
      "z=",
      function()
        Snacks.picker.spelling({ on_show = function() vim.cmd("stopinsert") end })
      end,
      desc = "Spell suggestions",
    },
    { "<leader>fb", function() Snacks.picker.buffers(function() vim.cmd("stopinsert") end) end, desc = "Buffers" },
    {
      "<leader>:",
      function()
        Snacks.picker.command_history({ layout = { preset = "code" }, function() vim.cmd("stopinsert") end })
      end,
      desc = "Command History",
    },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files (cwd)" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>sw", function() Snacks.picker.grep_word() end, mode = { "n", "x" }, desc = "Search word" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
    { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent files (cwd)" },
    { "<leader>fG", function() Snacks.picker.grep_buffers() end, desc = "Grep in Open Buffers" },
    { "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
    { "<leader>sm", function() Snacks.picker.man() end, desc = "Man Pages" },
    {
      "<leader>fc",
      function()
        Snacks.picker.resume({ exclude = { "explorer", "notifications" } })
      end,
      desc = "Continue from last search",
    },
    { "<leader>e", function() Snacks.explorer({ cwd = Utils.root() }) end, desc = "File explorer" },
    {"<leader>E", function() Snacks.explorer() end, desc = "File explorer (cwd)"},
    {
      "<leader>fe",
      function()
        if Snacks.picker.get({ source = "explorer" })[1] ~= nil then
          Snacks.picker.get({ source = "explorer" })[1]:focus()
        else
          Snacks.explorer({ cwd = Utils.root() })
        end
      end,
      desc = "Explorer Snacks (root dir)",
    },
  },
  -- stylua: ignore end
  config = function(_, opts)
    local notify = vim.notify
    require("snacks").setup(opts)
    vim.notify = notify
  end,
}
