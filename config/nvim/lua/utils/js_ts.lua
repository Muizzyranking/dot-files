local M = {}

function M.auto_add_async()
  vim.api.nvim_feedkeys("t", "n", true)
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local text_before_cursor = vim.api.nvim_get_current_line():sub(col - 3, col)
  if text_before_cursor ~= "awai" then return end

  local func_node = Utils.treesitter.find_node({ "arrow_function", "function_declaration", "function" })
  if not func_node then return end
  local func_text = vim.treesitter.get_node_text(func_node, 0)
  if not func_text then return end

  if vim.startswith(func_text, "async") then return end -- already async

  local start_row, start_col = func_node:start()
  vim.api.nvim_buf_set_text(0, start_row, start_col, start_row, start_col, { "async " })
end

return M
