local function augroup(name)
  return vim.api.nvim_create_augroup("nvim" .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].nvim_last_loc then
      return
    end
    vim.b[buf].nvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "checkhealth",
    "dbout",
    "gitsigns-blame",
    "grug-far",
    "help",
    "lspinfo",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "help",
    "lspinfo",
    "man",
    "help",
    "query",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("man_unlisted"),
  pattern = { "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  group = augroup("json_conceal"),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("js_ts"),
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact", "jsx", "tsx" },
  callback = function(event)
    Utils.map.set({
      {
        "t",
        Utils.lang.ts.auto_add_async,
        mode = "i",
        desc = "Auto add async",
        buffer = event.buf,
      },
    })
  end,
})

local cur_line_rel_num = augroup("toggle_rel_number")
vim.api.nvim_create_autocmd({ "FocusGained", "InsertLeave", "WinEnter" }, {
  group = cur_line_rel_num,
  pattern = "*",
  callback = function(event)
    local exclude = { "snacks_dashboard" }
    if vim.tbl_contains(exclude, vim.bo[event.buf].filetype) then
      return
    end
    vim.wo.cursorline = true
    if vim.wo.number then
      vim.wo.relativenumber = true
    end
  end,
})

vim.api.nvim_create_autocmd({ "FocusLost", "InsertEnter", "WinLeave" }, {
  group = cur_line_rel_num,
  pattern = "*",
  callback = function(event)
    local exclude = { "snacks_dashboard" }
    if vim.tbl_contains(exclude, vim.bo[event.buf].filetype) then
      return
    end
    if vim.wo.number then
      vim.wo.relativenumber = false
    end
    vim.wo.cursorline = false
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*",
  group = augroup("ft_detect"),
  callback = function()
    if vim.bo.filetype == "" then
      vim.cmd("filetype detect")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = vim.fn.expand("$HOME") .. "/dot-files/bin/*",
  callback = function(e)
    local buf = e.buf
    local filepath = Utils.fn.get_filepath(buf)
    if not Utils.fn.is_executable(filepath) then
      Utils.actions.toggle_file_executable(false, filepath, false)
    end
  end,
})

vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
  desc = "Remove hl search when enter Insert",
  callback = vim.schedule_wrap(function()
    vim.cmd.nohlsearch()
  end),
})
