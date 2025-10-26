---@class utils.ui
local M = {}
M.colorscheme = "habamax"
M.logo = nil

------------------------------------------------------------
-- sets the colorscheme
---@param colorscheme? string
------------------------------------------------------------
function M.set_colorscheme(colorscheme)
  if vim.g.vscode then return end
  M.colorscheme = colorscheme or M.colorscheme

  -- Create an autocmd that will apply the colorscheme when LazyVim is loaded
  Utils.autocmd.on_user_event("LazyDone", function()
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
  end)
end

-- close floating windows
function M.close_floats()
  vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win)
      return vim.api.nvim_win_get_config(win).relative ~= ""
    end)
    :each(function(win)
      vim.api.nvim_win_close(win, true)
    end)
end

function M.refresh(close_floats, buf_enter)
  if close_floats then M.close_floats() end
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

---@param logo_name? string
function M.set_logo(logo_name)
  if logo_name and M.logos[logo_name] then
    M.logo = M.logos[logo_name]
  else
    if logo_name then Utils.notify.warn("Unknown logo: " .. logo_name .. ", using default 'one'") end
    M.logo = M.logos.one
  end
end

function M.setup(opts)
  opts = opts or {}
  M.set_colorscheme(opts.colorscheme)
  M.set_logo(opts.logo)
end

M.logos = {}
M.logos.one = [[
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

M.logos.two = [[

  ███╗   ███╗██╗   ██╗██╗███████╗███████╗██╗   ██╗██████╗  █████╗ ███╗   ██╗██╗  ██╗██╗███╗   ██╗ ██████╗
  ████╗ ████║██║   ██║██║╚══███╔╝╚══███╔╝╚██╗ ██╔╝██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝██║████╗  ██║██╔════╝
    ██╔████╔██║██║   ██║██║  ███╔╝   ███╔╝  ╚████╔╝ ██████╔╝███████║██╔██╗ ██║█████╔╝ ██║██╔██╗ ██║██║  ███╗
    ██║╚██╔╝██║██║   ██║██║ ███╔╝   ███╔╝    ╚██╔╝  ██╔══██╗██╔══██║██║╚██╗██║██╔═██╗ ██║██║╚██╗██║██║   ██║
    ██║ ╚═╝ ██║╚██████╔╝██║███████╗███████╗   ██║   ██║  ██║██║  ██║██║ ╚████║██║  ██╗██║██║ ╚████║╚██████╔╝
  ╚═╝     ╚═╝ ╚═════╝ ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝
]]

M.logos.three = [[
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
