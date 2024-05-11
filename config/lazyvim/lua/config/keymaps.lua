local create_newfile = require("config.custom-func").new_file
-- local del = vim.keymap.del
local set = vim.keymap.set

set("n", "<leader>fn", create_newfile, { desc = "New file", noremap = true, silent = true })

set("n", "x", '"_x')

-- Select all
set("n", "<C-a>", "gg<S-v>G", { desc = "Select all", noremap = true, silent = true })

--use ctrl-q to quit
set("n", "<C-Q>", "<cmd>qa<cr>", { desc = "Quit all", noremap = true, silent = true })
set("n", "<C-q>", "<cmd>q<cr>", { desc = "Quit", noremap = true, silent = true })

-- set jj as esc key
set("i", "jj", "<esc>", { desc = "Esc", noremap = true, silent = true })

-- go to the end of a line
set("n", "E", "$", { noremap = true, silent = true })
set("v", "E", "$", { noremap = true, silent = true })
set("i", "<C-e>", "<esc>A", { noremap = true, silent = true })

-- go to beginning of the line
set("n", "B", "^", { noremap = true, silent = true })
set("v", "B", "^", { noremap = true, silent = true })
set("i", "<C-b>", "<esc>I", { noremap = true, silent = true })

--go to next line in insert mode
set("i", "<C-o>", "<esc>o")

-- dont copy when pasting over text
-- not working for some reasons, use P instead
-- TODO: check why this is not working
set("v", "p", '"_dP')
set("x", "p", '"_dP')

-- better indenting
--using <tab> and <s-tab> for indenting and dedenting
set("v", "<S-Tab>", "<gv", { noremap = false, silent = true })
set("v", "<Tab>", ">gv", { noremap = false, silent = true })

-- make file executable
set("n", "<leader>cx", "<cmd>!chmod +x % >/dev/null 2>&1<cr>", { desc = "Make file executable", silent = true })

-- Move to window using the <ctrl> hjkl keys in terminal mode
set("t", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
set("t", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
set("t", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
set("t", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
