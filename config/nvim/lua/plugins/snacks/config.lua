local M = {}

M.notifier = {
  timeout = 3000,
  width = { min = 40, max = 0.4 },
  height = { min = 1, max = 0.6 },
  margin = { top = 0, right = 1, bottom = 0 },
  padding = true,
  sort = { "level", "added" },
  level = vim.log.levels.TRACE,
  icons = {
    error = " ",
    warn = " ",
    info = " ",
    debug = " ",
    trace = " ",
  },
  keep = function()
    return vim.fn.getcmdpos() > 0
  end,
  filter = function(notif)
    local ignores = { "^client.supports_method is deprecated" }
    return not vim.iter(ignores):any(function(pat)
      return string.find(notif.msg, pat) ~= nil
    end)
  end,
  style = "compact",
  top_down = false,
  date_format = "%R",
  ---@type string|boolean
  more_format = " ↓ %d lines ",
  refresh = 50,
}

M.indent = {
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

M.dashboard = {
  preset = {
    header = [[

  ███╗   ███╗██╗   ██╗██╗███████╗███████╗██╗   ██╗██████╗  █████╗ ███╗   ██╗██╗  ██╗██╗███╗   ██╗ ██████╗
  ████╗ ████║██║   ██║██║╚══███╔╝╚══███╔╝╚██╗ ██╔╝██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝██║████╗  ██║██╔════╝
    ██╔████╔██║██║   ██║██║  ███╔╝   ███╔╝  ╚████╔╝ ██████╔╝███████║██╔██╗ ██║█████╔╝ ██║██╔██╗ ██║██║  ███╗
    ██║╚██╔╝██║██║   ██║██║ ███╔╝   ███╔╝    ╚██╔╝  ██╔══██╗██╔══██║██║╚██╗██║██╔═██╗ ██║██║╚██╗██║██║   ██║
    ██║ ╚═╝ ██║╚██████╔╝██║███████╗███████╗   ██║   ██║  ██║██║  ██║██║ ╚████║██║  ██╗██║██║ ╚████║╚██████╔╝
  ╚═╝     ╚═╝ ╚═════╝ ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝
]],
    keys = {
      -- stylua: ignore start
      { icon = " ", key = "n", desc = "New File", action = ":lua vim.cmd('enew')" },
      { icon = " ", key = "f", desc = "Find File", action = ":lua Utils.picker.files({ cwd = Utils.root() })" },
      { icon = " ", key = "g", desc = "Find Text", action = ":lua Utils.picker.grep()" },
      { icon = " ", key = "r", desc = "Recent Files", action = ":lua Utils.picker.recent()" },
      {
        icon = " ",
        key = "R",
        desc = "Recent Files (cwd)",
        action = ":lua Snacks.picker.recent({ filter = { cwd = true }, title = 'Recent Files (cwd)' })",
      },
      { icon = " ", key = "s", desc = "Restore Session", section = "session" },
      { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      -- stylua: ignore end
    },
  },
  sections = {
    { section = "header" },
    { section = "keys", gap = 1, padding = 1 },
    { section = "startup" },
  },
}

M.explorer = {
  on_show = function()
    Snacks.notifier.hide()
  end,
  on_close = function() end,
  format = function(item, picker)
    local ret = require("snacks.picker.format").file(item, picker)
    local item_path = Snacks.picker.util.path(item)
    local bufnr = vim.fn.bufnr(item_path)
    if bufnr ~= -1 and vim.bo[bufnr].modified then
      table.insert(ret, { "●", hl = "DiagnosticWarn" })
    end
    return ret
  end,
  layout = {
    layout = { position = "right" },
    preset = "sidebar",
    hidden = { "input" },
    auto_hide = { "input" },
  },
  include = { "*.zsh*", ".env.*", ".env", ".gitignore", ".dockerignore" },
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

M.layouts = {
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
}

M.picker = {
  prompt = " ",
  ui_select = true,
  layout = { preset = "ivy" },
  sources = {
    explorer = M.explorer,
    files = {
      exclude = { ".git", ".cache", "node_modules", "venv", ".venv", ".pytest_cache" },
      actions = {},
    },
    buffers = {
      sort_lastused = true,
      hidden = false,
      ignore_filetype = {},
      focus = "list",
      win = {
        input = {
          keys = {
            ["dd"] = "bufdelete",
            ["<c-x>"] = { "bufdelete", mode = { "n", "i" } },
          },
        },
        list = {
          keys = {
            ["dd"] = "bufdelete",
            ["s"] = "edit_vsplit",
            ["S"] = "edit_split",
          },
        },
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
  layouts = M.layouts,
  actions = {},
  win = {
    input = {
      keys = {
        ["<C-h>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
        ["s"] = "edit_vsplit",
        ["S"] = "edit_split",
      },
      b = { completion = false },
    },
    list = { keys = {} },
  },
}

return M
