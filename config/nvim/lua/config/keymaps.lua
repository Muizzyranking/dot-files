local set = vim.keymap.set

-- stylua: ignore start
------------------------
-- moving chunks of text/code
------------------------
set("n", "<A-j>", "<cmd>m .+1<cr>==",        { desc = "Move Down" })
set("n", "<A-k>", "<cmd>m .-2<cr>==",        { desc = "Move Up" })
set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
set("v", "<A-j>", ":m '>+1<cr>gv=gv",        { desc = "Move Down" })
set("v", "<A-k>", ":m '<-2<cr>gv=gv",        { desc = "Move Up" })

------------------------
-- navigation
------------------------
set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
set({ "n" }, "<C-h>", "<C-w>h",                     { desc = "Go to left window", remap = true })
set({ "n" }, "<C-j>", "<C-w>j",                     { desc = "Go to lower window", remap = true })
set({ "n" }, "<C-k>", "<C-w>k",                     { desc = "Go to upper window", remap = true })
set({ "n" }, "<C-l>", "<C-w>l",                     { desc = "Go to right window", remap = true })
set("t", "<Esc><Esc>", "<C-\\><C-n>",               { desc = "Exit terminal mode" })
set("t", "<C-h>", "<cmd>wincmd h<cr>",              { desc = "Go to Left Window" })
set("t", "<C-j>", "<cmd>wincmd j<cr>",              { desc = "Go to Lower Window" })
set("t", "<C-k>", "<cmd>wincmd k<cr>",              { desc = "Go to Upper Window" })
set("t", "<C-l>", "<cmd>wincmd l<cr>",              { desc = "Go to Right Window" })

------------------------
-- window management
------------------------
set("n", "<leader>ww", "<C-W>p",                     { desc = "Other Window", remap = true })
set("n", "<leader>wd", "<C-W>c",                     { desc = "Delete Window", remap = true })
set("n", "<leader>w-", "<C-W>s",                     { desc = "Split Window Below", remap = true })
set("n", "<leader>w|", "<C-W>v",                     { desc = "Split Window Right", remap = true })
set("n", "<leader>wn", "<C-W>n",                     { desc = "Split Window Right", remap = true })
set("n", "<leader>wo", "<C-W>o",                     { desc = "Close other windows", remap = true })
-- Resize window using <ctrl> arrow keys
set("n", "<C-Up>", "<cmd>resize +2<cr>",             { desc = "Increase Window Height" })
set("n", "<C-Down>", "<cmd>resize -2<cr>",           { desc = "Decrease Window Height" })
set("n", "<C-Left>", "<cmd>vertical resize -2<cr>",  { desc = "Decrease Window Width" })
set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

------------------------
-- saving and quitting
------------------------
set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>update<cr><esc>", { desc = "Save File" })
set("n", "<C-q>", "<cmd>q<cr>",       { desc = "Quit file" })
set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Save all and quit", silent = true })

------------------------
-- search
------------------------
-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
set("n", "N", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
set("x", "n", "'Nn'[v:searchforward]",      { expr = true, desc = "Next Search Result" })
set("o", "n", "'Nn'[v:searchforward]",      { expr = true, desc = "Next Search Result" })
set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
set("x", "N", "'nN'[v:searchforward]",      { expr = true, desc = "Prev Search Result" })
set("o", "N", "'nN'[v:searchforward]",      { expr = true, desc = "Prev Search Result" })
set("n", "<Esc>", "<cmd>nohlsearch<CR>") -- Clear search highlight on pressing <Esc> in normal mode

------------------------
-- editing
------------------------
if Utils.is_in_tmux() then
  set("i", "<C-o>", "<esc>o",  { desc = "Go to next line", remap = true }) -- go to next line in insert
else
  set("i", "<C-cr>", "<esc>o", { desc = "Go to next line" }) -- go to next line in insert
end
set("i", "<C-b>", "<esc>I",    { desc = "Go to beginning of line" }) -- Go to beginning of line in insert
set(                           { "n", "v" }, "B", "^", { desc = "Go to beginning of line" }) -- go to beginning of line in normal
set("i", "<C-e>", "<esc>A",    { desc = "Go to end of line" }) -- go to end of line in insert
set(                           { "n", "v" }, "E", "$", { desc = "Go to end of line" }) -- go to end of line in normal
-- set("i", "jj", "<Esc>",     { desc = "Go to normal mode" }) -- esc with jj
set("n", "<BS>", '"_ciw',      { desc = "Change inner word" }) -- change word

-- NOTE: this is the way to make <c-bs> work in tmux for some reasons
if Utils.is_in_tmux() then
  set({ "i", "c" }, "<c-h>", "<c-w>",  { desc = "Delete word" }) -- delete word with <c-bs>
else
  set({ "i", "c" }, "<C-BS>", "<c-w>", { desc = "Delete word" }) -- delete word with <c-bs>
end

set({ "n" }, "D", '"_D',      { desc = "Delete without yanking" }) -- delete line without yanking
set("n", "<C-a>", "gg<S-v>G", { desc = "Select all", noremap = true, silent = true }) -- select all
set("v", "<S-Tab>", "<gv",    { noremap = false, silent = true })
set("v", "<Tab>", ">gv",      { noremap = false, silent = true })
-- paste over currently selected text without yanking it
set({ "v", "x" }, "p", '"_dp')
set({ "v", "x" }, "P", '"_dp')
set({ "n", "v", "x" }, "c", '"_c')
set({ "n" }, "ciw", '"_ciw')
set({ "n" }, "C", '"_C')
set({ "n", "v", "x" }, "x", '"_x') -- delete text without yanking

-- set({ "n", "i", "t" }, "<C-_>", terminal, { noremap = true, silent = true, desc = "Toggle Terminal" })
set({ "n", "i", "t" }, "<F7>", Utils.terminal.float_term, { noremap = true, silent = true, desc = "Toggle Terminal" })
-- stylua: ignore end

-- disable arrow key in normal mode
set("n", "<UP>", function()
  Utils.notify.warn("Use k", { title = "options" })
end)
set("n", "<DOWN>", function()
  Utils.notify.warn("Use j", { title = "options" })
end)
set("n", "<LEFT>", function()
  Utils.notify.warn("Use h", { title = "options" })
end)
set("n", "<RIGHT>", function()
  Utils.notify.warn("Use l", { title = "options" })
end)

------------------------------------
-- keymaps with icons
------------------------------------
local maps = {
  {
    "<leader>bd",
    Snacks.bufdelete.delete,
    desc = "Delete buffer",
    icon = { icon = "󰛌 ", color = "red" },
  },
  {
    "<leader>bo",
    Snacks.bufdelete.other,
    desc = "Delete other buffers",
    icon = { icon = "󰛌 ", color = "red" },
  },
  {
    "<leader>cx",
    function()
      Utils.keys.toggle_file_executable()
    end,
    desc = function()
      local file = vim.fn.expand("%:p")
      return "Make file " .. (Utils.is_executable(file) and "unexecutable" or "executable")
    end,
    icon = function()
      local file = vim.fn.expand("%:p")
      return Utils.is_executable(file) and { icon = "󰜺 ", color = "yellow" } or { icon = "󱐌 ", color = "red" }
    end,
  },
  Utils.toggle_map({
    key = "<leader>uw",
    get_state = function()
      return vim.opt.wrap:get()
    end,
    toggle_fn = Utils.keys.toggle_line_wrap,
    desc = "line wrap",
  }),
  Utils.toggle_map({
    key = "<leader>ud",
    get_state = function()
      return not vim.diagnostic.is_disabled()
    end,
    toggle_fn = Utils.keys.toggle_diagnostics,
    desc = "diagnostic",
  }),
  Utils.toggle_map({
    key = "<leader>us",
    get_state = function()
      return vim.wo.spell
    end,
    toggle_fn = Utils.keys.toggle_spell,
    desc = "spell",
  }),
  Utils.toggle_map({
    key = "<leader>uf",
    get_state = function()
      return vim.g.autoformat
    end,
    toggle_fn = Utils.format.toggle,
    desc = "Autoformat (Global)",
  }),
  Utils.toggle_map({
    key = "<leader>uF",
    get_state = function()
      return Utils.format.enabled(vim.api.nvim_get_current_buf())
    end,
    toggle_fn = function()
      Utils.format.toggle(vim.api.nvim_get_current_buf())
    end,
    desc = "Autoformat (Buffer)",
  }),
  Utils.toggle_map({
    key = "<leader>uT",
    get_state = function()
      return vim.b.ts_highlight
    end,
    toggle_fn = function()
      if vim.b.ts_highlight then
        vim.treesitter.stop()
        Utils.notify.warn("Treesitter Highlight disabled", { title = "Options" })
      else
        vim.treesitter.start()
        Utils.notify.info("Treesitter Highlight enabled", { title = "Options" })
      end
    end,
    desc = "treesitter Highlight",
  }),
  {
    "<leader>j",
    function()
      Utils.keys.duplicate_line()
    end,
    desc = "Dulicate line",
    icon = { icon = "󰆑 " },
  },
  {
    "<leader>j",
    function()
      Utils.keys.duplicate_selection()
    end,
    desc = "Dulicate selection",
    icon = { icon = "󰆑 " },
    mode = { "v" },
  },
  {
    "<leader>/",
    "gcc",
    desc = "Comment line",
    icon = { icon = "󱆿 " },
    remap = true,
  },
  {
    "<leader>/",
    "gc",
    desc = "Comment line",
    icon = { icon = "󱆿 " },
    remap = true,
    mode = { "v", "x" },
  },
  {
    "<leader>fn",
    function()
      Utils.keys.new_file()
    end,
    desc = "Create new file",
    icon = { icon = " ", color = "orange" },
  },
  {
    "<leader>d",
    '"_d',
    desc = "Delete without yanking",
    icon = { icon = "󰛌 ", color = "red" },
    mode = { "v", "x" },
  },
  {
    "<leader>d",
    '"_dd',
    desc = "Delete without yanking",
    icon = { icon = "󰛌 ", color = "red" },
  },
  {
    "<leader>ut",
    Utils.keys.toggle_case,
    desc = "Change variable case",
    icon = { icon = "󰯍 ", color = "red" },
  },
}

if Utils.is_in_git_repo() then
  local git_maps = {
    {
      "<leader>gb",
      function()
        -- Utils.git.blame_line()
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
      icon = { icon = " ", color = "orange" },
    },
    {
      "<leader>gc",
      function()
        Snacks.lazygit.log()
      end,
      desc = "Lazygit log",
      icon = { icon = " ", color = "orange" },
    },
    {
      "<leader>gC",
      function()
        Snacks.lazygit.log_file()
      end,
      desc = "Lazygit log (current file)",
      icon = { icon = " ", color = "orange" },
    },
  }
  for _, git_map in ipairs(git_maps) do
    table.insert(maps, git_map)
  end
end

Utils.map(maps)
