if not Utils.is_in_git_repo() then
  return
end

local M = {}

function M.close_git_signs(key)
  key = key or "q"
  vim.keymap.set("n", key, function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      local bufname = Utils.get_filename(buf)
      if bufname:find("^gitsigns://") then
        vim.api.nvim_win_close(win, true)
        break
      end
    end
    vim.wo.diff = false
    return ""
  end, { buffer = true, expr = true, silent = true })
end

function M.close_unified(key)
  key = key or "q"
  vim.keymap.set("n", key, function()
    local buffer = Utils.ensure_buf(0)
    local un_diff = require("unified.diff")
    local state = require("unified.state")
    local is_diff_displayed = un_diff.is_diff_displayed(buffer)

    if is_diff_displayed or state.is_active() then
      vim.wo.diff = false
      require("unified.command").reset()
      Utils.ui.refresh()
      return ""
    end
    return "q"
  end, { expr = true, silent = true })
end

return M
