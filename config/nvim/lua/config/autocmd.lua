local function augroup(name)
  return vim.api.nvim_create_augroup("Neovim " .. name, { clear = true })
end

local create_autocmd = vim.api.nvim_create_autocmd

-----------------------------------------------------------
-- Reload config files on save
-----------------------------------------------------------
create_autocmd("BufWritePost", {
  group = augroup("reload configs"),
  pattern = {
    "*/kitty/kitty.conf",
    "*/tmux/tmux.conf",
    "*/waybar/config",
    "*/waybar/style.css",
  },
  callback = function()
    local file = vim.fn.expand("<afile>")
    local cmd = ""

    if file:match("kitty.conf$") then
      cmd = "kill -SIGUSR1 $(pgrep kitty)"
    elseif file:match("tmux.conf$") then
      cmd = "tmux source-file ~/.config/tmux/tmux.conf"
    elseif file:match("config$") or file:match("style.css$") then
      cmd = "if pgrep -x waybar > /dev/null; then killall waybar; fi; waybar &"
    end

    if cmd ~= "" then
      local output = vim.fn.system(cmd)
      local opts = { title = "Config Reload" }
      if vim.v.shell_error ~= 0 then
        Utils.notify.error("Error reloading config" .. output, opts)
      else
        Utils.notify.info("Config reloaded successfully", opts)
      end
    end

    if file:match("nvim/lua/*") and not file:match("nvim/lua/plugins/*") then
      vim.cmd("source " .. file)
      vim.notify("Sourced file: " .. file, vim.log.levels.INFO)
    end
  end,
})

-----------------------------------------------------------
-- Go to the last cursor position when opening a buffer
-----------------------------------------------------------
create_autocmd("BufWinEnter", {
  group = augroup("last_cursor"),
  desc = "jump to the last position when reopening a file",
  pattern = "*",
  command = [[ if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif ]],
})

-----------------------------------------------------------
-- Enable spell checking for certain file types
-----------------------------------------------------------
create_autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup("spell_check"),
  pattern = { "*.txt", "*.md", "markdown", "*.tex", "*.org" },
  callback = function()
    vim.opt.spell = true
    vim.opt.spelllang = "en"
  end,
})

-----------------------------------------------------------
-- Highlight yanked (copied) text
-----------------------------------------------------------
create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-----------------------------------------------------------
-- Close certain file types with q
-----------------------------------------------------------
create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "help",
    "lspinfo",
    "man",
    "help",
    "notify",
    "qf",
    "query",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "neotest-output",
    "checkhealth",
    "neotest-summary",
    "neotest-output-panel",
    "Telescope",
    "telescope",
    "grug-far",
    "AvanteInput",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-----------------------------------------------------------
-- Auto create directory when saving a file
-----------------------------------------------------------
create_autocmd({ "BufWritePre" }, {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-----------------------------------------------------------
-- Don't auto comment new line
-----------------------------------------------------------
create_autocmd("BufEnter", { command = [[set formatoptions-=cro]] })

-----------------------------------------------------------
-- Make it easier to close man-files when opened inline
-----------------------------------------------------------
create_autocmd("FileType", {
  group = augroup("man_unlisted"),
  pattern = { "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-----------------------------------------------------------
-- Turn off line numbering in terminal buffers
-----------------------------------------------------------
create_autocmd("TermOpen", {
  group = augroup("term_no_line_number"),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})

-----------------------------------------------------------
-- show cursor line and relativenumber only in active window
-- modified - https://github.com/jdhao/nvim-config/blob/main/lua/custom-autocmd.lua
-----------------------------------------------------------
local toggle_relnu = augroup("Relative line number toggle")
create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
  pattern = "*",
  group = toggle_relnu,
  desc = "togger line number",
  callback = function()
    if vim.w.auto_cursorline then
      vim.wo.cursorline = true
      vim.w.auto_cursorline = nil
    end
    if vim.wo.number then
      vim.wo.relativenumber = true
    end
  end,
})

create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
  pattern = "*",
  group = toggle_relnu,
  desc = "togger line number",
  callback = function()
    if vim.wo.number then
      vim.wo.relativenumber = false
    end
    if vim.wo.cursorline then
      vim.w.auto_cursorline = true
      vim.wo.cursorline = false
    end
  end,
})

-----------------------------------------------------------
-- Check if we need to reload the file when it changed
-----------------------------------------------------------
create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-----------------------------------------------------------
-- auto detects filetype if the filetype is empty
-----------------------------------------------------------
create_autocmd("BufWritePost", {
  pattern = "*",
  group = augroup("FileDetect"),
  callback = function()
    if vim.bo.filetype == "" then
      vim.cmd("filetype detect")
    end
  end,
})

-- Remove from menu
vim.api.nvim_command([[aunmenu PopUp.How-to\ disable\ mouse]])
-- -- Add to menu
vim.api.nvim_command([[menu PopUp.Format\ \Code <cmd>lua require("utils.format").format()<CR>]])
vim.api.nvim_command([[menu PopUp.-1- <Nop>]])
