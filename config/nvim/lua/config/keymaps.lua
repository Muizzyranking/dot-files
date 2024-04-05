-- local del = vim.keymap.del
local set = vim.keymap.set

set("n", "x", '"_x')

-- Select all
set("n", "<C-a>", "gg<S-v>G", { desc = "Select all", noremap = true, silent = true })

--toggleterm
set("n", "<C-_>", "<cmd>ToggleTerm<CR>", { desc = "Open Terminal", noremap = true, silent = true })

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

--dont copy when pasting over text
set("v", "p", '"_dP', { remap = true, silent = true })

--dont copy when changing text
-- set("v", "c", '"_dc', { remap = true, silent = true })

--run betty on the current file
-- set("n", "<leader>rb", "<cmd>!betty %<cr>", { silent = true, desc = "Run betty on current file" })

--run pycodestyle on the current file
-- set("n", "<leader>rp", "<cmd>!pycodestyle %<cr>", { desc = "Run pycodestyle on current file" })

--using <tab> and <s-tab> for indenting and dedenting
set("v", "<tab>", ">", { desc = "indent", remap = true, silent = true })
set("v", "<s-tab>", "<", { desc = "dedent", remap = true, silent = true })
