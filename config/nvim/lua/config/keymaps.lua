local set = vim.keymap.set
vim.keymap.set("n", "m", "<nop>", {})

------------------------
-- moving chunks of text/code
------------------------
set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

------------------------
-- navigation
------------------------
set({ "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
set({ "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
set({ "n" }, "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
set({ "n" }, "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
set({ "n" }, "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
set({ "n" }, "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })
set({ "n" }, "<C-p>", "<C-w>p", { desc = "Go to previous window", remap = true })
set({ "n" }, "<C-o>", "<C-o>zz", {})
set({ "n" }, "<C-i>", "<C-i>zz", {})
-- set({ "n" }, "<C-u>", "<C-u>zz",                    {})
-- set({ "n" }, "<C-d>", "<C-d>zz",                    {})
set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
set("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
set("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
set("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
set("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })

------------------------
-- window management
------------------------
set("n", "<leader>ww", "<C-W>p", { desc = "Other Window", remap = true })
set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
set("n", "<leader>w-", "<C-W>s", { desc = "Split Window Below", remap = true })
set("n", "<leader>w|", "<C-W>v", { desc = "Split Window Right", remap = true })
set("n", "<leader>wn", "<C-W>n", { desc = "Split Window Right", remap = true })
set("n", "<leader>wo", "<C-W>o", { desc = "Close other windows", remap = true })
set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

------------------------
-- saving and quitting
------------------------
set("n", "<C-S>", "<Cmd>silent! update | redraw<CR>", { desc = "Save" })
set({ "i", "x" }, "<C-S>", "<Esc><Cmd>silent! update | redraw<CR>", { desc = "Save and go to Normal mode" })
set("n", "<C-q>", "<cmd>q<cr>", { desc = "Quit file" })
set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Save all and quit", silent = true })

------------------------
-- search
------------------------
-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
set("n", "N", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
set("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
set("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
set("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
set("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- set("i", "jj", "<Esc>",     { desc = "Go to normal mode" }) -- esc with jj
set("n", "<BS>", '"_ciw', { desc = "Change inner word" }) -- change word
set({ "i", "c" }, "<c-h>", "<c-w>", { desc = "Delete word", silent = false })
set("v", "<S-Tab>", "<gv", { noremap = false, silent = true })
set("v", "<Tab>", ">gv", { noremap = false, silent = true })
set({ "n" }, "ciw", '"_ciw')

set("s", "<BS>", "<C-o>s", { desc = "Delete selection" })
set("s", "<C-h>", "<C-o>s", { desc = "Delete selection" })
set("i", "<tab>", Utils.actions.smart_tab, { desc = "Smart Tab" })
set("i", "<s-tab>", Utils.actions.smart_shift_tab, { desc = "Smart S-tab" })

set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
set("n", "<A-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
set("n", "<A-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
set("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
set("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

------------------------
-- editing
------------------------
set("i", "<C-Enter>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>o", true, false, true), "n", true)
end, { silent = true })

set("i", "<C-b>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>I", true, false, true), "n", true)
end, { desc = "Go to beginning of line" }) -- Go to beginning of line in insert

set("i", "<C-e>", function()
  vim.cmd.normal({ "$", bang = true })
  vim.cmd("startinsert!")
end, { desc = "Go to end of line" }) -- Go to end of line in insert

local function snippet_aware_map(modes, lhs, rhs, opts)
  opts = opts or {}
  opts.expr = true

  set(modes, lhs, function()
    if vim.snippet ~= nil and vim.snippet.active() then
      return lhs
    else
      return rhs
    end
  end, opts)
end

snippet_aware_map({ "n", "v", "x" }, "B", "^", { desc = "Go to beginning of line" })
snippet_aware_map({ "n", "v", "x" }, "E", "$", { desc = "Go to end of line" })
snippet_aware_map({ "v", "x" }, "p", '"_dp', {})
snippet_aware_map({ "v", "x" }, "P", '"_dP', {})
snippet_aware_map({ "n", "v", "x" }, "c", '"_c', {})
snippet_aware_map({ "n" }, "C", '"_C', {})
snippet_aware_map({ "n" }, "D", '"_D', {})
snippet_aware_map({ "n", "v", "x" }, "x", '"_x', {})
snippet_aware_map({ "n", "v", "x" }, "X", '"_X', {})

local function auto_indent(keys)
  keys = keys or { "i" }
  local opts = { silent = true }
  opts.expr = true
  opts.desc = opts.desc or "Auto-indent on insert enter"
  for _, key in ipairs(keys) do
    set("n", key, function()
      return not vim.api.nvim_get_current_line():match("%g") and '"_cc' or key
    end, opts)
  end
end

auto_indent({ "i", "I", "A", "a" })

set("n", "*", function()
  local save_cursor = vim.fn.getpos(".")
  vim.cmd("normal! *")
  vim.fn.setpos(".", save_cursor)
end, { noremap = true })

set("n", "#", function()
  local save_cursor = vim.fn.getpos(".")
  vim.cmd("normal! #")
  vim.fn.setpos(".", save_cursor)
end, { noremap = true })

set("n", "dd", function()
  local cond = vim.api.nvim_get_current_line():match("^%s*$")
  return cond and '"_dd' or "dd"
end, { desc = "Delete empty lines without yanking", expr = true })

set({ "n", "v", "x" }, "<esc>", function()
  vim.snippet.stop()
  vim.cmd("nohlsearch")
  return "<esc>"
end, { expr = true, desc = "Stop snippet and escape" })

for _, key in pairs({ "<UP>", "<DOWN>", "<LEFT>", "<RIGHT>" }) do
  set("n", key, "<nop>", { desc = "Disable " .. key })
end

local maps = {
  { "<leader>l", "<cmd>Lazy<cr>", desc = "Lazy" },
  {
    "<leader>ur",
    "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
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
      Utils.format({ force = true, bufnr = Utils.fn.ensure_buf(0) })
    end,
    desc = "Format buffer",
    icon = { icon = " ", color = "green" },
    mode = { "n", "v" },
  },
}

Utils.map.set(maps, { silent = true })

local git_maps = {
  {
    "<leader>go",
    function()
      Utils.fn.run_command({ "open-repo", "-b" }, {
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
    conds = { Utils.fn.is_executable("open-repo") },
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
    conds = { Utils.fn.is_executable("lazygit") },
  },
}

Utils.map.set(git_maps, {
  silent = true,
  icon = { icon = " ", color = "orange" },
  conds = {},
})

------------------------------------
-- toggle keymaps
------------------------------------
Utils.map.set({
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
      ---@diagnostic disable-next-line: undefined-field
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
      local fpath = Utils.fn.get_filepath(buf)
      return Utils.fn.is_executable(fpath)
    end,
    set = function(state, buf)
      local fpath = Utils.fn.get_filepath(buf)
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
})
