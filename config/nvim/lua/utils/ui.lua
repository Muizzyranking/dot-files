local M = {}

--------------------------------------------------
-- Get signs for a specific buffer and line number
---@param buf number
---@param lnum number
---@return Sign[]
--------------------------------------------------
function M.get_signs(buf, lnum)
  -- Get regular signs
  ---@type Sign[]
  local signs = {}
  -- Get extmark signs
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buf,
    -1,
    { lnum - 1, 0 },
    { lnum - 1, -1 },
    { details = true, type = "sign" }
  )
  for _, extmark in pairs(extmarks) do
    signs[#signs + 1] = {
      name = extmark[4].sign_hl_group or "",
      text = extmark[4].sign_text,
      texthl = extmark[4].sign_hl_group,
      priority = extmark[4].priority,
    }
  end

  -- Sort by priority
  table.sort(signs, function(a, b)
    return (a.priority or 0) < (b.priority or 0)
  end)

  return signs
end

--------------------------------------------------
-- Get mark for a specific buffer and line number
---@param buf number
---@param lnum number
---@return {text: string, texthl: string}|nil
--------------------------------------------------
function M.get_mark(buf, lnum)
  local marks = vim.fn.getmarklist(buf)
  vim.list_extend(marks, vim.fn.getmarklist())
  for _, mark in ipairs(marks) do
    if mark.pos[1] == buf and mark.pos[2] == lnum and mark.mark:match("[a-zA-Z]") then
      return { text = mark.mark:sub(2), texthl = "DiagnosticHint" }
    end
  end
end

--------------------------------------------------
-- Generate icon string from sign
---@param sign table|nil
---@param len number|nil
---@return string
--------------------------------------------------
function M.icon(sign, len)
  sign = sign or {}
  len = len or 2
  local text = vim.fn.strcharpart(sign.text or "", 0, len) ---@type string
  text = text .. string.rep(" ", len - vim.fn.strchars(text))
  return sign.texthl and ("%#" .. sign.texthl .. "#" .. text .. "%*") or text
end

--------------------------------------------------
-- Generate statuscolumn string
---@return string
--------------------------------------------------
function M.statuscolumn()
  local win = vim.g.statusline_winid
  local buf = vim.api.nvim_win_get_buf(win)
  local is_file = vim.bo[buf].buftype == ""
  local show_signs = vim.wo[win].signcolumn ~= "no"

  local components = { "", "", "" } -- left, middle, right

  if show_signs then
    ---@type Sign?,Sign?,Sign?
    local left, right, fold
    for _, s in ipairs(M.get_signs(buf, vim.v.lnum)) do
      if s.name and (s.name:find("GitSign") or s.name:find("MiniDiffSign")) then
        right = s
      else
        left = s
      end
    end
    if vim.v.virtnum ~= 0 then
      left = nil
    end
    vim.api.nvim_win_call(win, function()
      if vim.fn.foldclosed(vim.v.lnum) >= 0 then
        fold = { text = vim.opt.fillchars:get().foldclose or "", texthl = "Folded" }
      end
    end)
    -- Left: mark or non-git sign
    components[1] = M.icon(M.get_mark(buf, vim.v.lnum) or left)
    -- Right: fold icon or git sign (only if file)
    components[3] = is_file and M.icon(fold or right) or ""
  end

  -- Numbers in Neovim are weird
  -- They show when either number or relativenumber is true
  local is_num = vim.wo[win].number
  local is_relnum = vim.wo[win].relativenumber
  if (is_num or is_relnum) and vim.v.virtnum == 0 then
    if vim.v.relnum == 0 then
      components[2] = is_num and "%l" or "%r" -- the current line
    else
      components[2] = is_relnum and "%r" or "%l" -- other lines
    end
    components[2] = "%=" .. components[2] .. " " -- right align
  end

  if vim.v.virtnum ~= 0 then
    components[2] = "%= "
  end

  return table.concat(components, "")
end

--------------------------------------------------
-- Parse a single line using Tree-sitter for syntax highlighting
---@param linenr number: The line number to parse
---@return table|nil: A table of parsed line segments with
--                    highlighting information, or nil if parsing fail
--------------------------------------------------
local parse_line = function(linenr)
  local bufnr = vim.api.nvim_get_current_buf()

  local line = vim.api.nvim_buf_get_lines(bufnr, linenr - 1, linenr, false)[1]
  if not line then
    return nil
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok then
    return nil
  end

  local query = vim.treesitter.query.get(parser:lang(), "highlights")
  if not query then
    return nil
  end

  local tree = parser:parse({ linenr - 1, linenr })[1]

  local result = {}

  local line_pos = 0

  for id, node, metadata in query:iter_captures(tree:root(), 0, linenr - 1, linenr) do
    local name = query.captures[id]
    local start_row, start_col, end_row, end_col = node:range()

    local priority = tonumber(metadata.priority or vim.highlight.priorities.treesitter)

    if start_row == linenr - 1 and end_row == linenr - 1 then
      -- check for characters ignored by treesitter
      if start_col > line_pos then
        table.insert(result, {
          line:sub(line_pos + 1, start_col),
          { { "Folded", priority } },
          range = { line_pos, start_col },
        })
      end
      line_pos = end_col

      local text = line:sub(start_col + 1, end_col)
      table.insert(result, { text, { { "@" .. name, priority } }, range = { start_col, end_col } })
    end
  end

  local i = 1
  while i <= #result do
    -- find first capture that is not in current range and apply highlights on the way
    local j = i + 1
    while j <= #result and result[j].range[1] >= result[i].range[1] and result[j].range[2] <= result[i].range[2] do
      for k, v in ipairs(result[i][2]) do
        if not vim.tbl_contains(result[j][2], v) then
          table.insert(result[j][2], k, v)
        end
      end
      j = j + 1
    end

    -- remove the parent capture if it is split into children
    if j > i + 1 then
      table.remove(result, i)
    else
      -- highlights need to be sorted by priority, on equal prio, the deeper nested capture (earlier
      -- in list) should be considered higher prio
      if #result[i][2] > 1 then
        table.sort(result[i][2], function(a, b)
          return a[2] < b[2]
        end)
      end

      result[i][2] = vim.tbl_map(function(tbl)
        return tbl[1]
      end, result[i][2])
      result[i] = { result[i][1], result[i][2] }

      i = i + 1
    end
  end

  return result
end

--------------------------------------------------
-- Generate the custom fold text suffix
---@param foldstart number: The starting line number of the fold
---@return table: A table containing the fold suffix string and its highlight group
--------------------------------------------------
local function get_custom_foldtxt_suffix(foldstart)
  local fold_suffix_str = string.format("  %s [%s lines]", "┉┉┉", vim.v.foldend - foldstart + 1)
  return { fold_suffix_str, "@string.documentation" }
end

--------------------------------------------------
-- Create the custom fold text
---@param foldtxt_suffix table: The fold text suffix
---@param foldstart number: The starting line number of the fold
---@return table: A table representing the custom fold text with highlighting
--------------------------------------------------
local function get_custom_foldtext(foldtxt_suffix, foldstart)
  local line = vim.api.nvim_buf_get_lines(0, foldstart - 1, foldstart, false)[1]

  return {
    { "  ", "Folded" },
    { line, "Normal" },
    foldtxt_suffix,
  }
end

--------------------------------------------------
-- Function to generate the fold text
---@return table: The final fold text with all necessary components and highlighting
--------------------------------------------------
M.get_foldtext = function()
  local foldstart = vim.v.foldstart
  local foldtext = parse_line(foldstart)
  local foldtxt_suffix = get_custom_foldtxt_suffix(foldstart)

  if type(foldtext) == "string" then
    return get_custom_foldtext(foldtxt_suffix, foldstart)
  else
    if foldtext == nil then
      foldtext = { { "  ", "Folded" } }
    else
      table.insert(foldtext, 1, { "  ", "Folded" })
    end
    table.insert(foldtext, foldtxt_suffix)
    return foldtext
  end
end

return M
