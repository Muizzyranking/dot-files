local autocmd = Utils.autocmd

------------------------------------------------------------
-- Reload config keymap for different tools
-------------------------------------------------------------
autocmd.autocmd_augroup("Reload_config", {
  {
    pattern = "*/kitty/kitty.conf",
    callback = function(event)
      Utils.map.reload_config({
        cmd = "kill -SIGUSR1 $(pgrep kitty)",
        title = "Kitty",
        buffer = event.buf,
        cond = os.getenv("KITTY_WINDOW_ID") ~= nil,
      })
    end,
  },
  {
    pattern = "*/tmux/tmux.conf",
    callback = function(event)
      Utils.map.reload_config({
        cmd = "tmux source-file ~/.config/tmux/tmux.conf",
        title = "Tmux",
        buffer = event.buf,
        cond = Utils.is_in_tmux(),
      })
    end,
  },
  {
    pattern = { "*/waybar/*" },
    callback = function(event)
      Utils.map.reload_config({
        cmd = "waybar",
        restart = true,
        title = "Waybar",
        buffer = event.buf,
      })
      vim.diagnostic.enable(false, { bufnr = event.buf })
    end,
  },
  {
    pattern = { "*/swaync/*" },
    callback = function(event)
      Utils.map.reload_config({
        cmd = "swaync",
        restart = true,
        title = "Swaync",
        buffer = event.buf,
      })
      -- disable diagnoistics because of noise
      vim.diagnostic.enable(false, { bufnr = event.buf })
    end,
  },
}, { "BufEnter", "BufNewFile", "BufReadPost", "WinEnter" })

autocmd("BufEnter", {
  pattern = { ".env", ".env.*", "*.zsh", "*.zsh.*" },
  callback = function(event)
    -- disable diagnoistics because of noise
    vim.diagnostic.enable(false, { bufnr = event.buf })
  end,
})

-----------------------------------------------------------
-- Go to the last cursor position when opening a buffer
-----------------------------------------------------------
autocmd("BufWinEnter", {
  group = "last_cursor",
  desc = "jump to the last position when reopening a file",
  pattern = "*",
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = Utils.ensure_buf(event.buf)
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].nvim_last_loc then return end
    vim.b[buf].nvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

-----------------------------------------------------------
-- Enable spell checking for certain file types
-----------------------------------------------------------
autocmd({ "BufRead", "BufNewFile" }, {
  group = "spell_check",
  pattern = { "*.txt", "*.md", "markdown", "*.tex", "*.org" },
  callback = function(event)
    if vim.bo[event.buf].filetype ~= "requirements" then
      vim.opt_local.spell = true
      vim.opt_local.spelllang = "en"
    end
  end,
})

-----------------------------------------------------------
-- Highlight yanked (copied) text
-----------------------------------------------------------
autocmd("TextYankPost", {
  group = "highlight_yank",
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-----------------------------------------------------------
-- jump to last accessed window on closing the current one.
-----------------------------------------------------------
autocmd("WinClosed", {
  nested = true,
  group = "jump_to_last_window",
  callback = function()
    if vim.fn.expand("<amatch>") == vim.fn.win_getid() then vim.cmd("wincmd p") end
  end,
})

autocmd.autocmd_augroup("Filetype autocmds", {
  {
    pattern = { "html", "css", "typescript", "typescriptreact", "javascript", "javascriptreact", "jsx", "tsx" },
    callback = function(event)
      vim.bo[event.buf].shiftwidth = 2
      vim.bo[event.buf].tabstop = 2
    end,
  },
  {
    pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact", "jsx", "tsx" },
    callback = function(event)
      Utils.map.set_keymaps({
        {
          "t",
          Utils.js_ts.auto_add_async,
          mode = "i",
          desc = "Auto add async",
          buffer = event.buf,
        },
      })
    end,
  },
  {
    pattern = { "man" },
    callback = function(event)
      vim.bo[event.buf].buflisted = false
    end,
  },
  {
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
      "grug-far",
      "grug-far-history",
      "grug-far-help",
      "AvanteInput",
    },
    callback = function(event)
      vim.bo[event.buf].buflisted = false
      vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
  },
}, { "Filetype" })

-----------------------------------------------------------
-- Auto create directory when saving a file
-----------------------------------------------------------
autocmd({ "BufWritePre" }, {
  group = "auto_create_dir",
  callback = function(event)
    if event.match:match("^%w%w+://") then return end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-----------------------------------------------------------
-- Don't auto comment new line
-----------------------------------------------------------
autocmd("BufEnter", { command = [[set formatoptions-=cro]] })

--------------------------------------------------------------
----- Turn off line numbering in terminal buffers
--------------------------------------------------------------
autocmd("TermOpen", {
  group = "term_no_line_number",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})

-----------------------------------------------------------
-- show cursor line and relativenumber only in active window
-----------------------------------------------------------
autocmd.autocmd_augroup("toggle_rel_number", {
  {
    events = { "BufEnter", "FocusGained", "InsertLeave", "WinEnter" },
    pattern = "*",
    desc = "togger line number",
    callback = function()
      if vim.w.auto_cursorline then
        vim.wo.cursorline = true
        vim.w.auto_cursorline = nil
      end
      if vim.wo.number then vim.wo.relativenumber = true end
    end,
  },
  {
    events = { "BufLeave", "FocusLost", "InsertEnter", "WinLeave" },
    pattern = "*",
    desc = "togger line number",
    callback = function()
      if vim.b.bigfile then return end
      if vim.wo.number then vim.wo.relativenumber = false end
      if vim.wo.cursorline then
        vim.w.auto_cursorline = true
        vim.wo.cursorline = false
      end
    end,
  },
  {
    events = { "TermClose" },
    pattern = "*",
    desc = "restore line number settings after terminal close",
    callback = function()
      vim.defer_fn(function()
        local current_win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_is_valid(current_win) then
          if vim.wo.number then vim.wo.relativenumber = true end
          if vim.w.auto_cursorline then
            vim.wo.cursorline = true
            vim.w.auto_cursorline = nil
          end
        end
      end, 10)
    end,
  },
})

-----------------------------------------------------------
-- Check if we need to reload the file when it changed
-----------------------------------------------------------
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = "checktime",
  callback = function()
    if vim.o.buftype ~= "nofile" then vim.cmd("checktime") end
  end,
})

-----------------------------------------------------------
-- auto detects filetype if the filetype is empty
-----------------------------------------------------------
autocmd("BufWritePost", {
  pattern = "*",
  group = "FileDetect",
  callback = function()
    if vim.bo.filetype == "" then vim.cmd("filetype detect") end
  end,
})

-----------------------------------------------------------
-- make scripts in ~/dot_files/bin executable on save
-----------------------------------------------------------
autocmd("BufWritePost", {
  pattern = vim.fn.expand("$HOME") .. "/dot-files/bin/*",
  callback = function(e)
    local buf = e.buf
    local filepath = Utils.get_filepath(buf)
    if not Utils.is_executable(filepath) then Utils.actions.toggle_file_executable(false, filepath, false) end
  end,
})

-----------------------------------------------------------
-- Remove hl search when enter Insert
-----------------------------------------------------------
autocmd({ "InsertEnter", "CmdlineEnter" }, {
  desc = "Remove hl search when enter Insert",
  callback = vim.schedule_wrap(function()
    vim.cmd.nohlsearch()
  end),
})

-----------------------------------------------------------
-- put help page at the bottom
-----------------------------------------------------------
autocmd({ "FileType", "BufEnter", "BufWinEnter", "WinEnter" }, {
  pattern = "help",
  callback = function()
    vim.schedule(function()
      vim.cmd("wincmd J")
      vim.cmd("horizontal resize 15")
    end)
  end,
})

-----------------------------------------------------------
-- restore tmux bar if hidden
-----------------------------------------------------------
autocmd.on_user_event("TmuxBarToggle", function()
  autocmd("VimLeave", {
    callback = function()
      local handle = io.popen("tmux display-message -p '#{status}'")
      local status = handle:read("*a")
      handle:close()
      local state = status:match("on")
      if not state then vim.fn.system({ "tmux", "set-option", "-g", "status", "on" }) end
    end,
  })
end)

autocmd.on_user_event("PersistenceLoadPost", function()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local wins = vim.tbl_filter(function(win)
      return vim.fn.win_gettype(win) == ""
    end, vim.api.nvim_tabpage_list_wins(tab))

    if #wins > 1 then
      for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        local line_count = vim.api.nvim_buf_line_count(buf)
        if
          line_count == 0
          or line_count == 1
            and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
            and not vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
        then
          vim.api.nvim_win_close(win, false)
        end
      end
    end
  end
end, {
  group = "clear_empty_windows",
  desc = "Close empty windows after loading session.",
  nested = true,
})

require("utils.bigfile").setup()
