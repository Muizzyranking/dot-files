---@class utils.discipline
local M = {}

function M.setup()
  ---@type table?
  local ok = true
  for _, key in ipairs({ "h", "j", "k", "l", "+" }) do
    local count = 0
    local timer = assert(vim.uv.new_timer())
    local map = key
    vim.keymap.set("n", key, function()
      if vim.v.count > 0 then
        count = 0
      end
      if count >= 10 and vim.bo.buftype ~= "nofile" then
        ok = pcall(Utils.notify.warn, "Stop Spamming!", {
          icon = "💀",
          id = "cowboy",
          keep = function()
            return count >= 10
          end,
        })
        if not ok then
          return map
        end
      else
        count = count + 1
        timer:start(2000, 0, function()
          count = 0
        end)
        if key == "j" then
          return vim.v.count == 0 and "gj" or "j"
        elseif key == "k" then
          return vim.v.count == 0 and "gk" or "k"
        else
          return key
        end
      end
    end, { expr = true, silent = true })
  end
end

return M
