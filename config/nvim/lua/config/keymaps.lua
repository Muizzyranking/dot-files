local map = Utils.map

-- i don't use marks
vim.keymap.set("n", "m", "<nop>", {})

-- stylua: ignore start
------------------------
-- moving chunks of text/code
------------------------
map("n", "<A-j>", "<cmd>m .+1<cr>==",        { desc = "Move Down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==",        { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv",        { desc = "Move Down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv",        { desc = "Move Up" })

------------------------
-- navigation
------------------------
map({ "x" }, "j", "v:count == 0 ? 'gj' : 'j'",      { expr = true, silent = true })
map({ "x" }, "k", "v:count == 0 ? 'gk' : 'k'",      { expr = true, silent = true })
map({ "n" }, "<C-h>", "<C-w>h",                     { desc = "Go to left window", remap = true })
map({ "n" }, "<C-j>", "<C-w>j",                     { desc = "Go to lower window", remap = true })
map({ "n" }, "<C-k>", "<C-w>k",                     { desc = "Go to upper window", remap = true })
map({ "n" }, "<C-l>", "<C-w>l",                     { desc = "Go to right window", remap = true })
map({ "n" }, "<C-p>", "<C-w>p",                     { desc = "Go to previous window", remap = true })
map({ "n" }, "<C-o>", "<C-o>zz",                    {})
map({ "n" }, "<C-i>", "<C-i>zz",                    {})
-- set({ "n" }, "<C-u>", "<C-u>zz",                    {})
-- set({ "n" }, "<C-d>", "<C-d>zz",                    {})
map("t", "<Esc><Esc>", "<C-\\><C-n>",               { desc = "Exit terminal mode" })
map("t", "<C-h>", "<cmd>wincmd h<cr>",              { desc = "Go to Left Window" })
map("t", "<C-j>", "<cmd>wincmd j<cr>",              { desc = "Go to Lower Window" })
map("t", "<C-k>", "<cmd>wincmd k<cr>",              { desc = "Go to Upper Window" })
map("t", "<C-l>", "<cmd>wincmd l<cr>",              { desc = "Go to Right Window" })

------------------------
-- window management
------------------------
map("n", "<leader>ww", "<C-W>p",                     { desc = "Other Window", remap = true })
map("n", "<leader>wd", "<C-W>c",                     { desc = "Delete Window", remap = true })
map("n", "<leader>w-", "<C-W>s",                     { desc = "Split Window Below", remap = true })
map("n", "<leader>w|", "<C-W>v",                     { desc = "Split Window Right", remap = true })
map("n", "<leader>wn", "<C-W>n",                     { desc = "Split Window Right", remap = true })
map("n", "<leader>wo", "<C-W>o",                     { desc = "Close other windows", remap = true })
-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>",             { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>",           { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>",  { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

------------------------
-- saving and quitting
------------------------
map("n", "<C-S>", "<Cmd>silent! update | redraw<CR>",               { desc = "Save" })
map({ "i", "x" }, "<C-S>", "<Esc><Cmd>silent! update | redraw<CR>", { desc = "Save and go to Normal mode" })
map("n", "<C-q>", "<cmd>q<cr>",                                     { desc = "Quit file" })
map("n", "<leader>qq", "<cmd>qa<cr>",                               { desc = "Save all and quit", silent = true })

------------------------
-- search
------------------------
-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "N", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]",      { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]",      { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]",      { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]",      { expr = true, desc = "Prev Search Result" })


-- set("i", "jj", "<Esc>",     { desc = "Go to normal mode" }) -- esc with jj
map("n", "<BS>", '"_ciw',           { desc = "Change inner word" }) -- change word
map({ "i", "c" }, "<c-h>", "<c-w>", { desc = "Delete word", silent = false })
map("v", "<S-Tab>", "<gv",          { noremap = false, silent = true })
map("v", "<Tab>", ">gv",            { noremap = false, silent = true })
map({ "n" }, "ciw", '"_ciw')

map("s", "<BS>", "<C-o>s",          { desc = "Delete selection" })
map("s", "<C-h>", "<C-o>s",         { desc = "Delete selection" })
-- stylua: ignore end

------------------------
-- editing
------------------------
map("i", "<C-Enter>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>o", true, false, true), "n", true)
end, { silent = true })

map("i", "<C-b>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>I", true, false, true), "n", true)
end, { desc = "Go to beginning of line" }) -- Go to beginning of line in insert

map("i", "<C-e>", function()
  vim.cmd.normal({ "$", bang = true })
  vim.cmd("startinsert!")
end, { desc = "Go to end of line" }) -- Go to end of line in insert

map.snippet_aware_map({ "n", "v", "x" }, "B", "^", { desc = "Go to beginning of line" })
map.snippet_aware_map({ "n", "v", "x" }, "E", "$", { desc = "Go to end of line" })
map.snippet_aware_map({ "v", "x" }, "p", '"_dp', {})
map.snippet_aware_map({ "v", "x" }, "P", '"_dP', {})
map.snippet_aware_map({ "n", "v", "x" }, "c", '"_c', {})
map.snippet_aware_map({ "n" }, "C", '"_C', {})
map.snippet_aware_map({ "n" }, "D", '"_D', {})
map.snippet_aware_map({ "n", "v", "x" }, "x", '"_x', {})
map.snippet_aware_map({ "n", "v", "x" }, "X", '"_X', {})

map.auto_indent({ "i", "I", "A", "a" }, { silent = true })

-- search for word and stay there
map("n", "*", function()
  local save_cursor = vim.fn.getpos(".")
  vim.cmd("normal! *")
  vim.fn.setpos(".", save_cursor)
end, { noremap = true })

map("n", "#", function()
  local save_cursor = vim.fn.getpos(".")
  vim.cmd("normal! #")
  vim.fn.setpos(".", save_cursor)
end, { noremap = true })

map("n", "dd", function()
  local cond = vim.api.nvim_get_current_line():match("^%s*$")
  return cond and '"_dd' or "dd"
end, { desc = "Delete empty lines without yanking", expr = true })

map({ "n", "v", "x" }, "<esc>", function()
  Utils.cmp.snippet_stop()
  vim.cmd("nohlsearch")
  return "<esc>"
end, { expr = true, desc = "Stop snippet and escape" })

map("i", "<tab>", Utils.actions.smart_tab, { desc = "Smart Tab" })
map("i", "<s-tab>", Utils.actions.smart_shift_tab, { desc = "Smart S-tab" })

-- disable arrow key in normal mode
for _, key in pairs({ "<UP>", "<DOWN>", "<LEFT>", "<RIGHT>" }) do
  map("n", key, function()
    Utils.notify.warn("Use hjkl", { title = "options" })
  end, { desc = "Disable " .. key })
end

------------------------------------
-- keymaps with icons
------------------------------------
local maps = {
  { "<leader>l", "<cmd>Lazy<cr>", desc = "Lazy" },
  { "<leader>ux", Utils.ui.close_floats, desc = "Close all floating windows" },
  { "<leader>ur", Utils.ui.refresh, desc = "Refresh UI", icon = { icon = " ", color = "blue" } },
  {
    "<leader>uR",
    function()
      Utils.ui.refresh(true, true)
    end,
    desc = "Refresh UI",
    icon = { icon = " ", color = "blue" },
  },
  {
    "<leader>bd",
    Snacks.bufdelete.delete,
    desc = "Delete buffer",
    icon = { icon = "󰛌 ", color = "red" },
  },
  { "<leader>bo", Snacks.bufdelete.other, desc = "Delete other buffers", icon = { icon = "󰛌 ", color = "red" } },
  { "<leader>j", Utils.actions.duplicate_line, desc = "Dulicate line", icon = { icon = "󰆑 " } },
  {
    "<leader>j",
    Utils.actions.duplicate_selection,
    desc = "Dulicate selection",
    icon = { icon = "󰆑 " },
    mode = { "v" },
  },
  { "<leader>/", "gcc", desc = "Comment line", icon = { icon = "󱆿 " }, remap = true },
  { "<leader>/", "gc", desc = "Comment line", icon = { icon = "󱆿 " }, remap = true, mode = { "v", "x" } },
  {
    "<leader>d",
    '"_d',
    desc = "Delete without yanking",
    icon = { icon = "󰛌 ", color = "red" },
    mode = { "v", "x" },
  },
  { "<leader>d", '"_dd', desc = "Delete without yanking", icon = { icon = "󰛌 ", color = "red" } },
  {
    "<leader>cf",
    function()
      Utils.format({ force = true, bufnr = Utils.ensure_buf(0) })
    end,
    desc = "Format buffer",
    icon = { icon = " ", color = "green" },
    mode = { "n", "v" },
  },
}

map.set(maps, { silent = true })

local git_maps = {
  {
    "<leader>go",
    function()
      Utils.run_command({ "open-repo", "-b" }, {
        trim = true,
        callback = function(output, success)
          if not success then
            Utils.notify.error("Failed to open repo in browser: " .. output)
          else
            Utils.notify.info("Opening repo in browser...")
          end
        end,
      })
    end,
    desc = "Open repo in browser",
    icon = { icon = "󰌧 ", color = "red" },
    conds = { Utils.is_executable("open-repo") },
  },
  {
    "<leader>gb",
    function()
      Snacks.git.blame_line()
    end,
    desc = "Git blame",
    icon = { icon = " " },
  },
  {
    "<leader>gg",
    function()
      Snacks.lazygit()
    end,
    desc = "Lazygit",
    conds = { Utils.is_executable("lazygit") },
  },
}

map.set(git_maps, {
  silent = true,
  icon = { icon = " ", color = "orange" },
  conds = { Utils.git.is_in_git_repo },
})

------------------------------------
-- toggle keymaps
------------------------------------
map.set({
  {
    "<leader>z",
    get = function()
      return Snacks.zen.win ~= nil
    end,
    set = function()
      Snacks.zen.zoom()
    end,
    name = "zoom",
  },
  {
    "<leader>ut",
    get = function(buf)
      return Utils.treesitter.hl_is_active(buf)
    end,
    set = function(state, buf)
      vim.treesitter[state and "stop" or "start"](buf)
    end,
    name = "treesitter Highlight",
  },
  {
    "<leader>uF",
    get = function(buf)
      return Utils.format.enabled(buf)
    end,
    set = function(state, buf)
      Utils.format.toggle(buf, not state)
    end,
    name = "Autoformat (Buffer)",
  },
  {
    "<leader>uf",
    get = function()
      return vim.g.autoformat
    end,
    set = function(state)
      Utils.format.toggle(nil, not state)
    end,
    name = "Autoformat (Global)",
  },
  {
    "<leader>us",
    get = function()
      return vim.wo.spell
    end,
    set = function(state)
      vim.opt.spell = not state
    end,
    name = "spell",
  },
  {
    "<leader>ud",
    get = function(buf)
      return vim.diagnostic.is_enabled({ bufnr = buf })
    end,
    set = function(state, buf)
      vim.diagnostic.enable(not state, { bufnr = buf })
    end,
    name = "diagnostic (buffer)",
  },
  {
    "<leader>uD",
    get = function()
      return vim.diagnostic.is_enabled()
    end,
    set = function(state)
      vim.diagnostic.enable(not state)
    end,
    name = "diagnostic (global)",
  },
  {
    "<leader>uw",
    get = function()
      return vim.opt.wrap:get()
    end,
    set = function(state)
      vim.opt.wrap = not state
    end,
    name = "Line wrap",
  },
  {
    "<leader>cx",
    get = function(buf)
      local fpath = Utils.get_filepath(buf)
      return Utils.is_executable(fpath)
    end,
    set = function(state, buf)
      local fpath = Utils.get_filepath(buf)
      Utils.actions.toggle_file_executable(state, fpath)
    end,
    desc = function(state)
      return ("Make file %s"):format(state and "unexecutable" or "executable")
    end,
    notify = false,
    icon = {
      enabled = "󰜺 ",
      disabled = "󱐌 ",
    },
    color = {
      enabled = "yellow",
      disabled = "red",
    },
  },
  {
    "<leader>ub",
    get = function()
      local handle = io.popen("tmux display-message -p '#{status}'")
      local status = handle:read("*a")
      handle:close()
      return status:match("on")
    end,
    set = function(state)
      Utils.actions.toggle_tmux(state)
    end,
    desc = function(state)
      return ("%s Tmux Bar"):format(state and "Hide" or "Show")
    end,
    notify = false,
    conds = { Utils.is_in_tmux },
  },
})
