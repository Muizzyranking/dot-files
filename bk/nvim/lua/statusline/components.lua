---@class StatuslineComponents
local M = {}

-- ──────────────────────────────────────────────────────────────────────
-- Palette (Tokyo Night)
-- ──────────────────────────────────────────────────────────────────────

local p = {
  fg = "#c0caf5",
  fg_dim = "#9aa5ce",
  fg_dimmer = "#565f89",
  bg_dark = "#1a1b26",
  surface = "#24283b",
  red = "#f7768e",
  orange = "#ff9e64",
  green = "#9ece6a",
  blue = "#7aa2f7",
  cyan = "#7dcfff",
  purple = "#bb9af7",
  warning = "#e0af68",
  error = "#db4b4b",
  info = "#0db9d7",
  hint = "#1abc9c",
}

-- ──────────────────────────────────────────────────────────────────────
-- Highlight definitions (applied by init.lua on setup + ColorScheme)
-- ──────────────────────────────────────────────────────────────────────

M.highlights = {
  Statusline = { fg = p.fg_dim, bg = p.bg_dark },
  StatuslineNC = { fg = p.fg_dimmer, bg = p.bg_dark },
  StatuslineSep = { fg = p.fg_dimmer, bg = p.bg_dark },

  -- Mode pills
  StatuslineModeNormal = { fg = p.bg_dark, bg = p.blue, bold = true },
  StatuslineModeInsert = { fg = p.bg_dark, bg = p.green, bold = true },
  StatuslineModeVisual = { fg = p.bg_dark, bg = p.purple, bold = true },
  StatuslineModeReplace = { fg = p.bg_dark, bg = p.orange, bold = true },
  StatuslineModeCommand = { fg = p.bg_dark, bg = p.cyan, bold = true },
  StatuslineModeTerminal = { fg = p.bg_dark, bg = p.green, bold = true },

  -- Slant separators after mode pill (fg = mode color, bg = statusline bg)
  StatuslineSlantNormal = { fg = p.blue, bg = p.bg_dark },
  StatuslineSlantInsert = { fg = p.green, bg = p.bg_dark },
  StatuslineSlantVisual = { fg = p.purple, bg = p.bg_dark },
  StatuslineSlantReplace = { fg = p.orange, bg = p.bg_dark },
  StatuslineSlantCommand = { fg = p.cyan, bg = p.bg_dark },
  StatuslineSlantTerminal = { fg = p.green, bg = p.bg_dark },

  -- File
  StatuslineFilename = { fg = p.fg, bg = p.bg_dark, bold = true, italic = true },
  StatuslineFilenameModified = { fg = p.warning, bg = p.bg_dark, bold = true, italic = true },

  -- Git
  StatuslineBranch = { fg = p.fg_dim, bg = p.bg_dark, italic = true },
  StatuslineDiffAdd = { fg = p.green, bg = p.bg_dark },
  StatuslineDiffChange = { fg = p.warning, bg = p.bg_dark },
  StatuslineDiffDelete = { fg = p.red, bg = p.bg_dark },

  -- Diagnostics
  StatuslineDiagError = { fg = p.error, bg = p.bg_dark },
  StatuslineDiagWarn = { fg = p.warning, bg = p.bg_dark },
  StatuslineDiagInfo = { fg = p.info, bg = p.bg_dark },
  StatuslineDiagHint = { fg = p.hint, bg = p.bg_dark },

  -- LSP
  StatuslineLsp = { fg = p.green, bg = p.bg_dark, italic = true },

  -- Copilot
  StatuslineCopilotOk = { fg = p.green, bg = p.bg_dark },
  StatuslineCopilotWarn = { fg = p.warning, bg = p.bg_dark },
  StatuslineCopilotError = { fg = p.red, bg = p.bg_dark },

  -- Buffers
  StatuslineBuffers = { fg = p.fg_dim, bg = p.bg_dark },
  StatuslineBuffersDirty = { fg = p.warning, bg = p.bg_dark, bold = true },

  -- Misc
  StatuslineMacro = { fg = p.red, bg = p.bg_dark, bold = true },
  StatuslineSearch = { fg = p.cyan, bg = p.bg_dark, bold = true },
  StatuslinePosition = { fg = p.fg_dimmer, bg = p.bg_dark },
}

-- ──────────────────────────────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────────────────────────────

---@return integer
function M.stbuf()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

local SEP = "%#StatuslineSep# │ %#StatuslineNC#"
M.sep = SEP

-- ──────────────────────────────────────────────────────────────────────
-- Mode
-- ──────────────────────────────────────────────────────────────────────

local mode_map = {
  n = { label = "NORMAL", key = "Normal" },
  no = { label = "O-PEND", key = "Normal" },
  i = { label = "INSERT", key = "Insert" },
  ic = { label = "INSERT", key = "Insert" },
  v = { label = "VISUAL", key = "Visual" },
  V = { label = "V-LINE", key = "Visual" },
  s = { label = "SELECT", key = "Visual" },
  S = { label = "S-LINE", key = "Visual" },
  R = { label = "REPLACE", key = "Replace" },
  Rv = { label = "V-REPL", key = "Replace" },
  c = { label = "COMMAND", key = "Command" },
  cv = { label = "COMMAND", key = "Command" },
  r = { label = "PROMPT", key = "Command" },
  ["!"] = { label = "SHELL", key = "Command" },
  t = { label = "TERMINAL", key = "Terminal" },
  nt = { label = "TERMINAL", key = "Terminal" },
}
mode_map[""] = { label = "V-BLOCK", key = "Visual" }
mode_map[""] = { label = "S-BLOCK", key = "Visual" }

---@return string
function M.mode()
  local raw = vim.api.nvim_get_mode().mode
  local info = mode_map[raw] or { label = raw:upper(), key = "Normal" }
  return string.format("%%#StatuslineMode%s# %s %%#StatuslineSlant%s#%%#StatuslineNC#", info.key, info.label, info.key)
end

-- ──────────────────────────────────────────────────────────────────────
-- Branch + Diff (shown together, branch calls diff internally)
-- ──────────────────────────────────────────────────────────────────────

---@return string
function M.branch()
  local branch = vim.b.gitsigns_head or vim.g.gitsigns_head
  if not branch or branch == "" then
    return ""
  end
  local icons = (Utils and Utils.icons and Utils.icons.git) or {}
  local icon = icons.branch or ""
  return string.format("%%#StatuslineBranch# %s %s%%#StatuslineNC#", icon, branch)
end

---@return string
function M.diff()
  local gs = vim.b.gitsigns_status_dict
  if not gs then
    return ""
  end
  local icons = (Utils and Utils.icons and Utils.icons.git) or {}

  local parts = {}
  local added = gs.added or 0
  local changed = gs.changed or 0
  local removed = gs.removed or 0

  if added > 0 then
    table.insert(parts, string.format("%%#StatuslineDiffAdd#%s%d%%#StatuslineNC#", icons.added or "+", added))
  end
  if changed > 0 then
    table.insert(parts, string.format("%%#StatuslineDiffChange#%s%d%%#StatuslineNC#", icons.modified or "~", changed))
  end
  if removed > 0 then
    table.insert(parts, string.format("%%#StatuslineDiffDelete#%s%d%%#StatuslineNC#", icons.removed or "-", removed))
  end

  if #parts == 0 then
    return ""
  end
  return table.concat(parts, " ")
end

-- ──────────────────────────────────────────────────────────────────────
-- Macro recording
-- ──────────────────────────────────────────────────────────────────────

---@return string
function M.macro()
  local reg = vim.fn.reg_recording()
  if reg == "" then
    return ""
  end
  return string.format("%%#StatuslineMacro# 󰑋 @%s%%#StatuslineNC#", reg)
end

-- ──────────────────────────────────────────────────────────────────────
-- Filename (center)
-- ──────────────────────────────────────────────────────────────────────

local function truncate_path(rel, max)
  if #rel <= max then
    return rel
  end
  local parts = vim.split(rel, "/", { plain = true })
  if #parts <= 1 then
    return "…" .. rel:sub(-(max - 1))
  end
  local name = parts[#parts]
  local short = {}
  for i = 1, #parts - 1 do
    table.insert(short, parts[i]:sub(1, 1))
  end
  return table.concat(short, "/") .. "/" .. name
end

---@return string
function M.filename()
  local buf = M.stbuf()
  local full = vim.api.nvim_buf_get_name(buf)
  local cols = vim.o.columns

  if full == "" then
    return "%#StatuslineFilename# 󰈚 [No Name]%#StatuslineNC#"
  end

  local name = vim.fn.fnamemodify(full, ":t")
  local rel = vim.fn.fnamemodify(full, ":~:.")
  local max_len = cols > 120 and 60 or cols > 80 and 40 or 20
  local display = truncate_path(rel, max_len)

  -- icon from mini.icons
  local icon = "󰈚"
  local ok, MiniIcons = pcall(require, "mini.icons")
  if ok then
    local ic = MiniIcons.get("file", name)
    if ic and ic ~= "" then
      icon = ic
    end
  end

  local modified = vim.bo[buf].modified
  local readonly = vim.bo[buf].readonly or not vim.bo[buf].modifiable
  local hl = modified and "StatuslineFilenameModified" or "StatuslineFilename"
  local mod_icon = modified and " ●" or ""
  local ro_icon = readonly and " 󰌾" or ""

  return string.format("%%#%s# %s %s%s%s%%#StatuslineNC#", hl, icon, display, mod_icon, ro_icon)
end

-- ──────────────────────────────────────────────────────────────────────
-- Buffers
-- ──────────────────────────────────────────────────────────────────────

---@return string
function M.buffers()
  local listed = vim.fn.getbufinfo({ buflisted = 1 })
  local count = #listed
  if count == 0 then
    return ""
  end

  local dirty = 0
  for _, buf in ipairs(listed) do
    if vim.bo[buf.bufnr].modified then
      dirty = dirty + 1
    end
  end

  local icon = (Utils and Utils.icons and Utils.icons.ui and Utils.icons.ui.buffer) or "󰓩"
  local hl = dirty > 0 and "StatuslineBuffersDirty" or "StatuslineBuffers"
  local dirt = dirty > 0 and string.format(" ●%d", dirty) or ""

  return string.format("%%#%s# %s%d%s%%#StatuslineNC#", hl, icon, count, dirt)
end

-- ──────────────────────────────────────────────────────────────────────
-- Diagnostics
-- ──────────────────────────────────────────────────────────────────────

---@return string
function M.diagnostics()
  local buf = M.stbuf()
  local icons = (Utils and Utils.icons and Utils.icons.diagnostics) or {}

  local items = {
    { sev = vim.diagnostic.severity.ERROR, hl = "StatuslineDiagError", icon = icons.error or " " },
    { sev = vim.diagnostic.severity.WARN, hl = "StatuslineDiagWarn", icon = icons.warn or " " },
    { sev = vim.diagnostic.severity.INFO, hl = "StatuslineDiagInfo", icon = icons.info or " " },
    { sev = vim.diagnostic.severity.HINT, hl = "StatuslineDiagHint", icon = icons.hint or "󰌶 " },
  }

  local parts = {}
  for _, item in ipairs(items) do
    local n = #vim.diagnostic.get(buf, { severity = item.sev })
    if n > 0 then
      table.insert(parts, string.format("%%#%s#%s%d%%#StatuslineNC#", item.hl, item.icon, n))
    end
  end

  if #parts == 0 then
    return ""
  end
  return table.concat(parts, " ")
end

-- ──────────────────────────────────────────────────────────────────────
-- LSP
-- ──────────────────────────────────────────────────────────────────────

local function truncate_lsp(name)
  if #name <= 10 then
    return name
  end
  if name:find("_") then
    name = name:match("([^_]+)") or name
  end
  if #name > 10 then
    name = name:sub(1, 10) .. "…"
  end
  return name
end

---@return string
function M.lsp()
  if vim.o.columns <= 100 then
    return ""
  end
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local names = {}
  for _, c in ipairs(clients) do
    if c.name ~= "conform" and c.name ~= "copilot" then
      table.insert(names, #clients > 2 and truncate_lsp(c.name) or c.name)
    end
  end
  if #names == 0 then
    return ""
  end
  return string.format("%%#StatuslineLsp# 󰄭 %s%%#StatuslineNC#", table.concat(names, ", "))
end

-- ──────────────────────────────────────────────────────────────────────
-- Copilot
-- ──────────────────────────────────────────────────────────────────────

local copilot_icons = { Normal = Utils.icons.kinds.Copilot, Warning = " ", InProgress = " ", Error = " " }
local copilot_hls = {
  Normal = "StatuslineCopilotOk",
  Warning = "StatuslineCopilotWarn",
  InProgress = "StatuslineCopilotWarn",
  Error = "StatuslineCopilotError",
}

---@return string
function M.copilot()
  if not package.loaded["copilot"] then
    return ""
  end
  local ok, clients = pcall(vim.lsp.get_clients, { name = "copilot", bufnr = 0 })
  if not ok or #clients == 0 then
    return ""
  end
  local sok, status = pcall(function()
    return require("copilot.status").data
  end)
  local s = (sok and status and status.status) or "Normal"
  return string.format(
    "%%#%s# %s%%#StatuslineNC#",
    copilot_hls[s] or copilot_hls.Normal,
    copilot_icons[s] or copilot_icons.Normal
  )
end

-- ──────────────────────────────────────────────────────────────────────
-- Search count
-- ──────────────────────────────────────────────────────────────────────

---@return string
function M.searchcount()
  if vim.v.hlsearch == 0 then
    return ""
  end
  local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 50 })
  if not ok or not result or result.total == 0 then
    return ""
  end
  if result.incomplete == 1 then
    return "%#StatuslineSearch#  ?/?%#StatuslineNC#"
  end
  return string.format("%%#StatuslineSearch#  %d/%d%%#StatuslineNC#", result.current, result.total)
end

-- ──────────────────────────────────────────────────────────────────────
-- Position bar only
-- ──────────────────────────────────────────────────────────────────────

local bar_chars = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

---@return string
function M.position()
  local line = vim.fn.line(".")
  local total = vim.fn.line("$")
  local ratio = line / math.max(total, 1)
  local bar = bar_chars[math.max(1, math.ceil(ratio * #bar_chars))]
  return string.format("%%#StatuslinePosition# %s%%#StatuslineNC#", bar)
end

-- ──────────────────────────────────────────────────────────────────────
-- Noice compat
-- ──────────────────────────────────────────────────────────────────────

---@return string
function M.noice_command()
  if not package.loaded["noice"] then
    return ""
  end
  local ok, noice = pcall(require, "noice")
  if not ok or not noice.api.status.command.has() then
    return ""
  end
  return string.format("%%#StatuslineNC# %s%%#StatuslineNC#", noice.api.status.command.get())
end

---@return string
function M.noice_mode()
  if not package.loaded["noice"] then
    return ""
  end
  local ok, noice = pcall(require, "noice")
  if not ok or not noice.api.status.mode.has() then
    return ""
  end
  return string.format("%%#StatuslineMacro# %s%%#StatuslineNC#", noice.api.status.mode.get())
end

return M
