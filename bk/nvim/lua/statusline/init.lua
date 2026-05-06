---@class Statusline
---Custom statusline engine. Section layout: left | center | right.
---Each section is a list of component functions () -> string.
---Empty strings are filtered — no gaps from disabled components.
local M = {}

local C = require("statusline.components")

-- ──────────────────────────────────────────────────────────────────────
-- Highlights
-- ──────────────────────────────────────────────────────────────────────

local function setup_highlights()
  for name, opts in pairs(C.highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

-- ──────────────────────────────────────────────────────────────────────
-- Section rendering
-- ──────────────────────────────────────────────────────────────────────

local SEP = C.sep

---Render a section — calls each fn, filters empty, joins with separator.
---@param components (fun(): string)[]
---@return string
local function render(components)
  local parts = {}
  for _, fn in ipairs(components) do
    local ok, result = pcall(fn)
    if ok and type(result) == "string" and result ~= "" then
      table.insert(parts, result)
    end
  end
  return table.concat(parts, SEP)
end

-- ──────────────────────────────────────────────────────────────────────
-- Layouts
-- ──────────────────────────────────────────────────────────────────────

---@class StatuslineLayout
---@field left   (fun(): string)[]
---@field center (fun(): string)[]
---@field right  (fun(): string)[]

---@type StatuslineLayout
local default_layout = {
  left = {
    C.mode,
    C.branch,
    C.diff,
    C.macro,
  },
  center = {
    C.filename,
  },
  right = {
    C.noice_command,
    C.noice_mode,
    C.searchcount,
    C.buffers,
    C.diagnostics,
    C.copilot,
    C.lsp,
    C.position,
  },
}

-- Per-filetype layouts. Add more with M.add_filetype().
---@type table<string, StatuslineLayout>
local ft_layouts = {
  lazygit = {
    left = {
      function()
        return "%#StatuslineModeCommand#  Lazygit%#StatuslineNC#"
      end,
      C.branch,
    },
    center = {},
    right = {},
  },
  snacks_picker_list = {
    left = {
      function()
        local picker = Snacks and Snacks.picker and Snacks.picker.get()[1]
        local title = (picker and picker.title) or "Picker"
        return string.format("%%#StatuslineModeVisual# 🍿 %s%%#StatuslineNC#", title)
      end,
      function()
        return string.format("%%#StatuslineBranch# %s%%#StatuslineNC#", vim.fn.fnamemodify(vim.fn.getcwd(), ":~"))
      end,
    },
    center = {},
    right = {
      function()
        local picker = Snacks and Snacks.picker and Snacks.picker.get()[1]
        if not picker then
          return ""
        end
        return string.format("%%#StatuslinePosition# %d items%%#StatuslineNC#", #picker:items())
      end,
    },
  },
  snacks_picker_input = {
    left = {
      function()
        local picker = Snacks and Snacks.picker and Snacks.picker.get()[1]
        local title = (picker and picker.title) or "Picker"
        return string.format("%%#StatuslineModeVisual# 🍿 %s%%#StatuslineNC#", title)
      end,
    },
    center = {},
    right = {
      function()
        local picker = Snacks and Snacks.picker and Snacks.picker.get()[1]
        if not picker then
          return ""
        end
        local count = #picker:items()
        return string.format("%%#StatuslinePosition# %d results%%#StatuslineNC#", count)
      end,
    },
  },
  sidekick_terminal = {
    left = {
      C.mode,
      function()
        local ok, state = pcall(require, "sidekick.cli.state")
        if not ok then
          return ""
        end
        local attached = state.get({ attached = true })
        if #attached == 0 then
          return ""
        end
        return string.format("%%#StatuslineLsp#  %s%%#StatuslineNC#", attached[1].tool.name or "Sidekick")
      end,
    },
    center = {},
    right = {},
  },
  -- Minimal tool filetypes
  oil = {
    left = {
      function()
        return "%#StatuslineModeCommand#  Oil%#StatuslineNC#"
      end,
    },
    center = { C.filename },
    right = {},
  },
  ["neo-tree"] = {
    left = {
      function()
        return "%#StatuslineModeCommand#  Neo-tree%#StatuslineNC#"
      end,
    },
    center = {},
    right = {},
  },
  lazy = {
    left = {
      function()
        return "%#StatuslineModeCommand# 💤 Lazy%#StatuslineNC#"
      end,
    },
    center = {},
    right = {},
  },
  mason = {
    left = {
      function()
        return "%#StatuslineModeCommand#  Mason%#StatuslineNC#"
      end,
    },
    center = {},
    right = {},
  },
  trouble = {
    left = {
      function()
        return "%#StatuslineModeCommand# 󱂠  Trouble%#StatuslineNC#"
      end,
    },
    center = {},
    right = {},
  },
  man = {
    left = {
      function()
        return "%#StatuslineModeCommand#  Man%#StatuslineNC#"
      end,
    },
    center = { C.filename },
    right = {},
  },
}

-- Filetypes that should show NO statusline at all
local hidden_ft = {
  dashboard = true,
  snacks_dashboard = true,
}

-- ──────────────────────────────────────────────────────────────────────
-- Render
-- ──────────────────────────────────────────────────────────────────────

---Called by vim on every statusline redraw via `%!v:lua.require('statusline').render()`.
---@return string
function M.render()
  local buf = C.stbuf()
  local ft = vim.bo[buf].filetype

  if hidden_ft[ft] then
    return ""
  end

  local layout = ft_layouts[ft] or default_layout

  local left = render(layout.left)
  local center = render(layout.center)
  local right = render(layout.right)

  -- Two %= for true centering: left + padding, center, padding + right
  return " " .. left .. "%=" .. center .. "%=" .. right .. " "
end

-- ──────────────────────────────────────────────────────────────────────
-- Public API
-- ──────────────────────────────────────────────────────────────────────

---Add or replace a per-filetype layout.
---@param ft string
---@param layout StatuslineLayout
function M.add_filetype(ft, layout)
  ft_layouts[ft] = layout
end

---Add a component to a section of the default layout.
---@param section "left"|"center"|"right"
---@param fn fun(): string
---@param pos? integer  Insert position (nil = append)
function M.add_component(section, fn, pos)
  local s = default_layout[section]
  if pos then
    table.insert(s, pos, fn)
  else
    table.insert(s, fn)
  end
end

-- ──────────────────────────────────────────────────────────────────────
-- Setup
-- ──────────────────────────────────────────────────────────────────────

function M.setup()
  -- Global statusline (one bar for all splits)
  vim.o.laststatus = 3

  setup_highlights()

  local group = vim.api.nvim_create_augroup("statusline.core", { clear = true })

  -- Re-apply highlights on colorscheme change
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = setup_highlights,
  })

  -- Refresh on relevant events
  vim.api.nvim_create_autocmd({
    "ModeChanged",
    "BufEnter",
    "BufWritePost",
    "BufModifiedSet",
    "FileType",
    "DiagnosticChanged",
    "LspAttach",
    "LspDetach",
    "RecordingEnter",
    "RecordingLeave",
    "SearchWrapped",
  }, {
    group = group,
    callback = function()
      vim.cmd.redrawstatus()
    end,
  })

  -- Use %! so vim calls render() on every redraw
  -- NOTE: no %S / showcmd here — it breaks inputs (snacks picker etc.)
  vim.o.statusline = "%!v:lua.require('statusline').render()"

  -- Start recency tracker
end

return M
