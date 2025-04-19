local set = Utils.map

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
set({ "n" }, "<C-p>", "<C-w>p",                     { desc = "Go to previous window", remap = true })
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
-- stylua: ignore end

------------------------
-- editing
------------------------
set("i", ("<c-%s>"):format(Utils.is_in_tmux() and "o" or "cr"), "<esc>o", { desc = "Go to next line", remap = true }) -- go to next line in insert

-- set("i", "<C-b>", "<esc>I", { desc = "Go to beginning of line" }) -- Go to beginning of line in insert
set("i", "<C-b>", function()
  vim.cmd.normal({ "I", bang = true })
end, { desc = "Go to beginning of line" }) -- Go to beginning of line in insert
set({ "n", "v" }, "B", "^", { desc = "Go to beginning of line" }) -- go to beginning of line in normal

set.snippet_aware_map({ "v", "x" }, "B", "^", {})
set.snippet_aware_map({ "v", "x" }, "p", '"_dp', {})
set.snippet_aware_map({ "v", "x" }, "P", '"_dP', {})
set.snippet_aware_map({ "n", "v", "x" }, "c", '"_c', {})
set.snippet_aware_map({ "n" }, "C", '"_C', {})
set.snippet_aware_map({ "n" }, "D", '"_D', {})
set.snippet_aware_map({ "n", "v", "x" }, "x", '"_x', {})

set("i", "<C-e>", "<esc>A", { desc = "Go to end of line" }) -- go to end of line in insert
set({ "n", "v" }, "E", "$", { desc = "Go to end of line" }) -- go to end of line in normal
-- set("i", "jj", "<Esc>",     { desc = "Go to normal mode" }) -- esc with jj
set("n", "<BS>", '"_ciw', { desc = "Change inner word" }) -- change word
-- NOTE: this is the way to make <c-bs> work in tmux for some reasons
set({ "i", "c" }, ("<C-%s>"):format(Utils.is_in_tmux() and "h" or "BS"), "<c-w>", { desc = "Delete word" })
set("n", "<C-a>", "gg<S-v>G", { desc = "Select all", noremap = true, silent = true }) -- select all
set("v", "<S-Tab>", "<gv", { noremap = false, silent = true })
set("v", "<Tab>", ">gv", { noremap = false, silent = true })
set({ "n" }, "ciw", '"_ciw')
set({ "i" }, "<c-v>", "<c-r>+", { desc = "Paste in insert mode", silent = false })

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
    "<leader>j",
    function()
      Utils.actions.duplicate_line()
    end,
    desc = "Dulicate line",
    icon = { icon = "󰆑 " },
  },
  {
    "<leader>j",
    function()
      Utils.actions.duplicate_selection()
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
    Utils.actions.change_var_case,
    desc = "Change variable case",
    icon = { icon = "󰯍 ", color = "red" },
  },
  {
    "go",
    function()
      if Utils.is_executable("open-repo") then
        vim.fn.system({ "open-repo" })
      else
        Utils.notify.warn("Command to open repo not available")
      end
    end,
    desc = "Open repo in browser",
    icon = { icon = "󰌧 ", color = "red" },
  },
}

if Utils.is_in_git_repo() then
  vim.list_extend(maps, {
    {
      "<leader>gb",
      function()
        Snacks.git.blame_line()
      end,
      desc = "Git blame",
      icon = { icon = " " },
    },
  })
  if Utils.is_executable("lazygit") then
    vim.list_extend(maps, {
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
    })
  end
end

set.set_keymaps(maps, { silent = true })

------------------------------------
-- toggle keymaps
------------------------------------
local toggle_maps = {
  {
    "<leader>uT",
    get_state = function()
      return vim.b.ts_highlight
    end,
    change_state = function(state)
      vim.treesitter[state and "stop" or "start"]()
    end,
    name = "treesitter Highlight",
  },
  {
    "<leader>uF",
    get_state = function()
      return Utils.format.enabled(vim.api.nvim_get_current_buf())
    end,
    change_state = function(state)
      Utils.format.toggle(vim.api.nvim_get_current_buf(), not state)
    end,
    name = "Autoformat (Buffer)",
  },
  {
    "<leader>uf",
    get_state = function()
      return vim.g.autoformat
    end,
    -- toggle_fn = Utils.format.toggle,
    change_state = function(state)
      Utils.format.toggle(nil, not state)
    end,
    name = "Autoformat (Global)",
  },
  {
    "<leader>us",
    get_state = function()
      return vim.wo.spell
    end,
    change_state = function(state)
      vim.opt.spell = not state
    end,
    name = "spell",
  },
  {
    "<leader>ud",
    get_state = function()
      return vim.diagnostic.is_enabled()
    end,
    change_state = function(state)
      vim.diagnostic.enable(not state)
    end,
    name = "diagnostic",
  },
  {
    "<leader>uw",
    get_state = function()
      return vim.opt.wrap:get()
    end,
    change_state = function(state)
      vim.opt.wrap = not state
    end,
    name = "Line wrap",
  },
  {
    "<leader>cx",
    get_state = function()
      return Utils.is_executable(vim.fn.expand("%:p"))
    end,
    change_state = function(state)
      Utils.actions.toggle_file_executable(state)
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
}

local is_executed = false
if Utils.is_in_tmux() then
  vim.list_extend(toggle_maps, {
    {
      "<leader>ub",
      get_state = function()
        local handle = io.popen("tmux display-message -p '#{status}'")
        local status = handle:read("*a")
        handle:close()
        return status:match("on")
      end,
      change_state = function(state)
        if not is_executed then
          vim.api.nvim_exec_autocmds("User", { pattern = "TmuxBarToggle" })
          is_executed = true
        end
        vim.system({ "tmux", "set-option", "-g", "status", ("%s"):format(state and "off" or "on") })
        Utils.notify(("%s Tmux Bar"):format(state and "Hide" or "Show"), { title = "Tmux" })
      end,
      desc = function(state)
        return ("%s Tmux Bar"):format(state and "Hide" or "Show")
      end,
      notify = false,
    },
  })
end

set.toggle_maps(toggle_maps)
