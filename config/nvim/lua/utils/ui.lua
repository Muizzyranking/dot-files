---@class utils.ui
local M = {}
M.colorscheme = "habamax"

------------------------------------------------------------
-- sets the colorscheme
---@param colorscheme? string
------------------------------------------------------------
function M.set_colorscheme(colorscheme)
  if vim.g.vscode then
    return
  end
  M.colorscheme = colorscheme or M.colorscheme

  -- Create an autocmd that will apply the colorscheme when LazyVim is loaded
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    callback = function()
      local ok = pcall(function()
        vim.cmd.colorscheme(M.colorscheme)
      end)
      if not ok then
        Utils.notify.error("Failed to load colorscheme: " .. M.colorscheme)
        M.colorscheme = "habamax"
        pcall(function()
          vim.cmd.colorscheme(M.colorscheme)
        end)
      end
    end,
  })
end

function M.refresh(close_floats, buf_enter)
  if close_floats then
    M.close_floats()
  end
  pcall(vim.cmd, "nohlsearch")
  pcall(vim.cmd, "diffupdate")
  if buf_enter then
    pcall(vim.cmd, "e!")
    pcall(function()
      vim.api.nvim_exec_autocmds("BufEnter", {})
      vim.api.nvim_exec_autocmds("WinEnter", {})
    end)
  end
  pcall(vim.cmd, "normal! \\<C-L>")
  vim.cmd("redraw!")
end

M.logo = {}
M.logo.one = [[
┈╭━━━━━━━━━━━╮┈
┈┃╭━━━╮┊╭━━━╮┃┈
╭┫┃┈▇┈┃┊┃┈▇┈┃┣╮
┃┃╰━━━╯┊╰━━━╯┃┃
╰┫╭━╮╰━━━╯╭━╮┣╯
┈┃┃┣┳┳┳┳┳┳┳┫┃┃┈
┈┃┃╰┻┻┻┻┻┻┻╯┃┃┈
┈╰━━━━━━━━━━━╯┈
=MUIZZYRANKING=

]]

M.logo.two = [[

  ███╗   ███╗██╗   ██╗██╗███████╗███████╗██╗   ██╗██████╗  █████╗ ███╗   ██╗██╗  ██╗██╗███╗   ██╗ ██████╗
  ████╗ ████║██║   ██║██║╚══███╔╝╚══███╔╝╚██╗ ██╔╝██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝██║████╗  ██║██╔════╝
    ██╔████╔██║██║   ██║██║  ███╔╝   ███╔╝  ╚████╔╝ ██████╔╝███████║██╔██╗ ██║█████╔╝ ██║██╔██╗ ██║██║  ███╗
    ██║╚██╔╝██║██║   ██║██║ ███╔╝   ███╔╝    ╚██╔╝  ██╔══██╗██╔══██║██║╚██╗██║██╔═██╗ ██║██║╚██╗██║██║   ██║
    ██║ ╚═╝ ██║╚██████╔╝██║███████╗███████╗   ██║   ██║  ██║██║  ██║██║ ╚████║██║  ██╗██║██║ ╚████║╚██████╔╝
  ╚═╝     ╚═╝ ╚═════╝ ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝
]]

M.logo.three = [[
⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣴⣶⣶⣶⣶⣶⠶⣶⣤⣤⣀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⣤⣾⣿⣿⣿⠁⠀⢀⠈⢿⢀⣀⠀⠹⣿⣿⣿⣦⣄⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⠿⠀⠀⣟⡇⢘⣾⣽⠀⠀⡏⠉⠙⢛⣿⣷⡖⠀
⠀⠀⠀⠀⠀⣾⣿⣿⡿⠿⠷⠶⠤⠙⠒⠀⠒⢻⣿⣿⡷⠋⠀⠴⠞⠋⠁⢙⣿⣄
⠀⠀⠀⠀⢸⣿⣿⣯⣤⣤⣤⣤⣤⡄⠀⠀⠀⠀⠉⢹⡄⠀⠀⠀⠛⠛⠋⠉⠹⡇
⠀⠀⠀⠀⢸⣿⣿⠀⠀⠀⣀⣠⣤⣤⣤⣤⣤⣤⣤⣼⣇⣀⣀⣀⣛⣛⣒⣲⢾⡷
⢀⠤⠒⠒⢼⣿⣿⠶⠞⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⣼⠃
⢮⠀⠀⠀⠀⣿⣿⣆⠀⠀⠻⣿⡿⠛⠉⠉⠁⠀⠉⠉⠛⠿⣿⣿⠟⠁⠀⣼⠃⠀
⠈⠓⠶⣶⣾⣿⣿⣿⣧⡀⠀⠈⠒⢤⣀⣀⡀⠀⠀⣀⣀⡠⠚⠁⠀⢀⡼⠃⠀⠀
⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣷⣤⣤⣤⣤⣭⣭⣭⣭⣭⣥⣤⣤⣤⣴⣟⠁
====MUIZZYRANKING====
--             ]]

return M
