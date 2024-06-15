-- Create an augroup with the given name and clear it
local function augroup(name)
  return vim.api.nvim_create_augroup("Neovim " .. name, { clear = true })
end

local create_autocmd = vim.api.nvim_create_autocmd

-----------------------------------------------------------
-- Go to the last cursor position when opening a buffer
-----------------------------------------------------------
create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
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
----- change filetype for htmldjango to html
-----------------------------------------------------------
create_autocmd("FileType", {
  pattern = "htmldjango",
  group = augroup("html_django"),
  callback = function()
    vim.bo.filetype = "html"
  end,
})

local web_fts = {
  "css",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "lua",
  "markdown",
  "python",
  "typescript",
  "typescriptreact",
  "yaml",
}
create_autocmd("FileType", {
  group = augroup("Web filetypes options"),
  pattern = web_fts,
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
  end,
})

create_autocmd("Filetype", {
  group = augroup("C options"),
  pattern = { "c", "cpp" },
  callback = function()
    vim.bo.shiftwidth = 8
    vim.bo.tabstop = 8
    vim.bo.softtabstop = 8
    vim.bo.expandtab = false
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
  end,
})

create_autocmd("Filetype", {
  group = augroup("Python options"),
  pattern = { "python" },
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
    vim.keymap.set("n", "<leader>cv", "<cmd>VenvSelect<cr>", { desc = "Select VirtualEnv" })
  end,
})
