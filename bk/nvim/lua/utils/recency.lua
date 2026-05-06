---@class utils.recency
local M = {}

---@type integer[]
local stack = {}

local function remove(buf)
  for i, b in ipairs(stack) do
    if b == buf then
      table.remove(stack, i)
      return
    end
  end
end

local function is_valid(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == ""
end

function M.setup()
  local group = vim.api.nvim_create_augroup("statusline.recency", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      local buf = ev.buf
      if not is_valid(buf) then
        return
      end
      remove(buf)
      table.insert(stack, 1, buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    callback = function(ev)
      remove(ev.buf)
    end,
  })
end

---@return integer[]
function M.list()
  return vim.tbl_filter(is_valid, stack)
end

--- Go to the previous buffer in recency order.
function M.prev()
  local list = M.list()
  -- list[1] is current, list[2] is previous
  if list[2] then
    vim.api.nvim_set_current_buf(list[2])
  else
    vim.notify("No previous buffer", vim.log.levels.INFO)
  end
end

function M.next()
  local list = M.list()
  local current = vim.api.nvim_get_current_buf()
  for i, buf in ipairs(list) do
    if buf == current and list[i + 1] then
      vim.api.nvim_set_current_buf(list[i + 1])
      return
    end
  end
  vim.notify("No next buffer", vim.log.levels.INFO)
end

return M
