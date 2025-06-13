vim.keymap.set("n", "q", function()
  local has_diff = vim.wo.diff
  if not has_diff then
    return "q"
  end

  if Utils.has("unufied.nvim") then
    local buffer = Utils.ensure_buf(0)
    local un_diff = require("unified.diff")
    local is_diff_displayed = un_diff.is_diff_displayed(buffer)

    if is_diff_displayed then
      vim.wo.diff = false
      require("unified.command").reset()
      Utils.ui.refresh()
      return ""
    end
  end
  -- Look for gitsigns buffer
  local target_win
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local bufname = Utils.get_filename(buf)
    if bufname:find("^gitsigns://") then
      target_win = win
      break
    end
  end

  if target_win then
    vim.schedule(function()
      vim.api.nvim_win_close(target_win, true)
    end)
    return ""
  end

  return "q"
end, { expr = true, silent = true })
