-- copied from https://github.com/NvChad/ui/tree/v3.0/lua/nvchad/colorify
local M = {}

---@class Config
---@field enabled boolean
---@field mode "virtual"|"fg"|"bg"
---@field virt_text string
---@field highlight table<string, boolean>
local DEFAULT_CONFIG = {
  enabled = true,
  mode = "virtual",
  virt_text = "󱓻 ",
  highlight = {
    hex = true,
    lspvars = true,
  },
}

---@class State
---@field events table
---@field ns integer
local state = {
  events = {},
  ns = vim.api.nvim_create_namespace("Colorify"),
  enabled = true,
}

-- Cache frequently used API calls
local api = vim.api
local fn = vim.fn

-- Utility functions
local utils = {}

---Determines if a color is dark based on its brightness
---@param hex string
---@return boolean
utils.is_dark = function(hex)
  hex = hex:gsub("#", "")
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)
  return ((r * 299 + g * 587 + b * 114) / 1000) < 128
end

---Creates a highlight group for a hex color
---@param hex string
---@param config Config
---@return string highlight_group_name
utils.create_highlight = function(hex, config)
  local name = "hex_" .. hex:sub(2)
  local fg, bg = hex, hex

  if config.mode == "bg" then
    fg = utils.is_dark(hex) and "white" or "black"
  else
    bg = "none"
  end

  api.nvim_set_hl(0, name, { fg = fg, bg = bg, default = true })
  return name
end

---Checks if a position needs highlighting
---@param buf integer
---@param line integer
---@param col integer
---@param hl_group string
---@param opts table
---@return boolean
utils.needs_highlight = function(buf, line, col, hl_group, opts)
  local marks = api.nvim_buf_get_extmarks(buf, state.ns, { line, col }, { line, opts.end_col }, { details = true })

  if #marks == 0 then
    return true
  end

  local mark = marks[1]
  opts.id = mark[1]
  return hl_group ~= (mark[4].hl_group or mark[4].virt_text and mark[4].virt_text[1][2])
end

-- Color processing methods
local methods = {
  ---Process hex color matches in a line
  ---@param buf integer
  ---@param line integer
  ---@param content string
  ---@param config Config
  hex = function(buf, line, content, config)
    for col, hex in content:gmatch("()(#%x%x%x%x%x%x)") do
      col = col - 1
      local hl_group = utils.create_highlight(hex, config)
      local opts = {
        end_col = col + 7,
        hl_group = hl_group,
      }

      if config.mode == "virtual" then
        opts.hl_group = nil
        opts.virt_text_pos = "inline"
        opts.virt_text = { { config.virt_text, hl_group } }
      end

      if utils.needs_highlight(buf, line, col, hl_group, opts) then
        api.nvim_buf_set_extmark(buf, state.ns, line, col, opts)
      end
    end
  end,

  ---Process LSP color provider information
  ---@param buf integer
  ---@param line? integer
  ---@param min? integer
  ---@param max? integer
  ---@param config Config
  lsp_var = function(buf, line, min, max, config)
    local params = { textDocument = vim.lsp.util.make_text_document_params(buf) }

    for _, client in pairs(vim.lsp.get_clients({ bufnr = buf })) do
      if not client.server_capabilities.colorProvider then
        goto continue
      end

      client.request("textDocument/documentColor", params, function(_, response)
        if not response then
          return
        end

        local filtered_response = response
        if line then
          filtered_response = vim.tbl_filter(function(v)
            return v.range["start"].line == line
          end, response)
        elseif min and max then
          filtered_response = vim.tbl_filter(function(v)
            return v.range["start"].line >= min and v.range["end"].line <= max
          end, response)
        end

        for _, match in ipairs(filtered_response) do
          local color = match.color
          local hex = string.format(
            "#%02x%02x%02x",
            color.red * color.alpha * 255,
            color.green * color.alpha * 255,
            color.blue * color.alpha * 255
          )

          local hl_group = utils.create_highlight(hex, config)
          local range_start = match.range.start
          local range_end = match.range["end"]

          local opts = {
            end_col = range_end.character,
            hl_group = hl_group,
          }

          if config.mode == "virtual" then
            opts.hl_group = nil
            opts.virt_text_pos = "inline"
            opts.virt_text = { { config.virt_text, hl_group } }
          end

          if utils.needs_highlight(buf, range_start.line, range_start.character, hl_group, opts) then
            api.nvim_buf_set_extmark(buf, state.ns, range_start.line, range_start.character, opts)
          end
        end
      end, buf)
      ::continue::
    end
  end,
}

---Attach buffer handlers for cleaning up extmarks
---@param buf integer
local function attach_buffer_handlers(buf)
  if vim.b[buf].colorify_attached then
    return
  end

  vim.b[buf].colorify_attached = true
  api.nvim_buf_attach(buf, false, {
    on_bytes = function(_, b, _, s_row, s_col, _, old_e_row, old_e_col, _, _, new_e_col, _)
      if old_e_row == 0 and new_e_col == 0 and old_e_col == 0 then
        return
      end

      local row1, col1, row2, col2
      if old_e_row > 0 then
        row1, col1, row2, col2 = s_row, 0, s_row + old_e_row, 0
      else
        row1, col1, row2, col2 = s_row, s_col, s_row, s_col + old_e_col
      end

      local marks = api.nvim_buf_get_extmarks(b, state.ns, { row1, col1 }, { row2, col2 }, { overlap = true })

      for _, mark in ipairs(marks) do
        api.nvim_buf_del_extmark(b, state.ns, mark[1])
      end
    end,
    on_detach = function()
      vim.b[buf].colorify_attached = false
    end,
  })
end

-- Add toggle functionality
---Toggle the plugin on/off
---@return boolean new_state
function M.toggle()
  state.enabled = not state.enabled

  if state.enabled then
    -- Reattach autocommands and refresh current buffer
    M.setup()
    local current_buf = vim.api.nvim_get_current_buf()
    if vim.bo[current_buf].bl then
      local winid = fn.bufwinid(current_buf)
      local min = fn.line("w0", winid) - 1
      local max = fn.line("w$", winid) + 1
      local lines = api.nvim_buf_get_lines(current_buf, min, max, false)

      if DEFAULT_CONFIG.highlight.hex then
        for i, content in ipairs(lines) do
          methods.hex(current_buf, min + i - 1, content, DEFAULT_CONFIG)
        end
      end
      if DEFAULT_CONFIG.highlight.lspvars then
        methods.lsp_var(current_buf, nil, min, max, DEFAULT_CONFIG)
      end
    end
  else
    -- Clear all extmarks
    local bufs = vim.api.nvim_list_bufs()
    for _, buf in ipairs(bufs) do
      if vim.api.nvim_buf_is_valid(buf) then
        local marks = api.nvim_buf_get_extmarks(buf, state.ns, 0, -1, {})
        for _, mark in ipairs(marks) do
          api.nvim_buf_del_extmark(buf, state.ns, mark[1])
        end
      end
    end
  end

  return state.enabled
end

---Get the current state of the plugin
---@return boolean
function M.get_state()
  return state.enabled
end

---Setup function to initialize the plugin
---@param config? table
function M.setup(config)
  config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, config or {})
  if not config.enabled or not state.enabled then
    return
  end
  Utils.map({
    Utils.toggle_map({
      key = "<leader>uh",
      get_state = M.get_state,
      toggle_fn = M.toggle,
      desc = "color highlight",
    }),
  })
  api.nvim_create_autocmd({
    "TextChanged",
    "TextChangedI",
    "TextChangedP",
    "VimResized",
    "LspAttach",
    "WinScrolled",
    "BufEnter",
  }, {
    callback = function(args)
      if not vim.bo[args.buf].bl then
        return
      end

      local winid = fn.bufwinid(args.buf)
      local min = fn.line("w0", winid) - 1
      local max = fn.line("w$", winid) + 1

      if args.event == "TextChangedI" then
        local cur_line = fn.line(".", winid) - 1
        if config.highlight.hex then
          methods.hex(args.buf, cur_line, api.nvim_get_current_line(), config)
        end
        if config.highlight.lspvars then
          methods.lsp_var(args.buf, cur_line, nil, nil, config)
        end
        return
      end

      local lines = api.nvim_buf_get_lines(args.buf, min, max, false)

      if config.highlight.hex then
        for i, content in ipairs(lines) do
          methods.hex(args.buf, min + i - 1, content, config)
        end
      end

      if config.highlight.lspvars then
        methods.lsp_var(args.buf, nil, min, max, config)
      end

      if args.event == "BufEnter" then
        attach_buffer_handlers(args.buf)
      end
    end,
  })
end

return M
