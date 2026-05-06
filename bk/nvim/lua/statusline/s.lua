---@class Statusline
local M = {}

local C = require("statusline.comp")

local function setup_highlights()
  for name, opts in pairs(C.highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

---Render a section — calls each fn, filters empty strings, joins with separator.
---Components that are cached return instantly. Components that are fast
---compute inline. Either way, render() itself stays cheap.
local PILL_TAG = "\x01PILL\x01"

---@param components (fun(): string)[]
---@return string
local function render(components)
  local parts = {}
  local prev_was_pill = false

  for _, fn in ipairs(components) do
    local ok, result = pcall(fn)
    if ok and type(result) == "string" and result ~= "" then
      local is_pill = result:sub(1, #PILL_TAG) == PILL_TAG
      local clean = is_pill and result:sub(#PILL_TAG + 1) or result

      if #parts > 0 and not prev_was_pill then
        table.insert(parts, C.sep)
      end

      table.insert(parts, clean)
      prev_was_pill = is_pill
    end
  end

  return table.concat(parts)
end

local default_layout = {
  left = {
    C.mode,
    C.branch,
    C.diff,
    C.macro,
    C.showcmd,
  },
  center = {
    C.filename,
  },
  right = {
    C.searchcount,
    C.buffers,
    C.diagnostics,
    C.copilot,
    C.lsp,
    C.position,
  },
}

local hidden_ft = {
  dashboard = true,
  snacks_dashboard = true,
}

local ft_layouts = {
  lazygit = {
    left = {
      function()
        return C.pill(" Lazygit")
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
        return C.pill(string.format("🍿 %s", title))
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
        return C.pill(string.format("🍿 %s", title))
      end,
      function()
        local picker = Snacks and Snacks.picker and Snacks.picker.get()[1]
        if not picker then
          return ""
        end
        return string.format("%%#StatuslinePosition# %d results%%#StatuslineNC#", #picker:items())
      end,
    },
    center = {},
    right = {},
  },

  oil = {
    left = {
      function()
        return C.pill("Oil")
      end,
    },
    center = { C.filename },
    right = {},
  },
  lazy = {
    left = {
      function()
        return C.pill("󰒲 Lazy")
      end,
    },
    center = {},
    right = {},
  },
  mason = {
    left = {
      function()
        return C.pill("󰏗 Mason")
      end,
    },
    center = {},
    right = {},
  },
  trouble = {
    left = {
      function()
        return C.pill("󰛩 Trouble")
      end,
    },
    center = {},
    right = {},
  },
  man = {
    left = {
      function()
        return C.pill("Man")
      end,
    },
    center = { C.filename },
    right = {},
  },
}

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

  return left .. "%=" .. center .. "%=" .. right .. " "
end

---Add or replace a per-filetype layout.
---@param ft string
---@param layout StatuslineLayout
function M.add_filetype(ft, layout)
  ft_layouts[ft] = layout
end

---@param section "left"|"center"|"right"
---@param fn fun(): string
---@param pos? integer
function M.add_component(section, fn, pos)
  local s = default_layout[section]
  if pos then
    table.insert(s, pos, fn)
  else
    table.insert(s, fn)
  end
end

function M.setup()
  vim.o.laststatus = 3

  setup_highlights()

  local group = vim.api.nvim_create_augroup("statusline.core", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = setup_highlights,
  })

  vim.api.nvim_create_autocmd({
    "ModeChanged",
    "RecordingEnter",
    "RecordingLeave",
    "CmdlineEnter",
    "CmdlineLeave",
    "CursorHold",
    "CursorHoldI",
    "WinScrolled",
  }, {
    group = group,
    callback = function()
      vim.schedule(function()
        vim.cmd.redrawstatus()
      end)
    end,
  })

  vim.o.statusline = "%!v:lua.require('statusline.s').render()"
end

return M
