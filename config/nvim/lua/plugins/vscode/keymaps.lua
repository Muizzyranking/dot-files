local opts = { noremap = true, silent = true }
vim.g.mapleader = " "
local map = vim.keymap.set
local del = vim.keymap.del
local vscode = require("vscode-neovim")

-- Function to create VSCode action mappings
local function vscode_map(mode, lhs, command, user_opts)
  local options = vim.tbl_extend("force", opts, user_opts or {})
  pcall(function()
    del(mode, lhs)
  end)
  map(mode, lhs, function()
    vscode.call(command)
  end, options)
end

-- Navigation between windows
vscode_map("n", "<C-h>", "workbench.action.navigateLeft", { desc = "Go to left window" })
vscode_map("n", "<C-j>", "workbench.action.navigateDown", { desc = "Go to lower window" })
vscode_map("n", "<C-k>", "workbench.action.navigateUp", { desc = "Go to upper window" })
vscode_map("n", "<C-l>", "workbench.action.navigateRight", { desc = "Go to right window" })
vscode_map("n", "<C-p>", "workbench.action.navigateLast", { desc = "Go to previous window" })

vscode_map("n", "<s-h>", "workbench.action.previousEditor", { desc = "Go to previous window" })
vscode_map("n", "<s-l>", "workbench.action.nextEditor", { desc = "Go to previous window" })
vscode_map("n", "<leader> ", "workbench.action.showCommands", { desc = "Go to previous window" })

-- Window management
vscode_map("n", "<leader>ww", "workbench.action.navigateLast", { desc = "Other Window" })
vscode_map("n", "<leader>wd", "workbench.action.closeActiveEditor", { desc = "Delete Window" })
vscode_map("n", "<leader>w-", "workbench.action.splitEditorDown", { desc = "Split Window Below" })
vscode_map("n", "<leader>w\\", "workbench.action.splitEditorRight", { desc = "Split Window Right" })
vscode_map("n", "<leader>wo", "workbench.action.closeOtherEditors", { desc = "Close other windows" })
vscode_map("n", "<leader>ws", "workbench.action.closeEditorsInGroup", { desc = "Close split" })

-- vscode_map({ "i", "x", "n", "s" }, "<C-s>", "workbench.action.files.save", { desc = "Save File" })
-- vscode_map({ "i", "x", "n", "s" }, "<C-s>", "workbench.action.files.saveAll", { desc = "Save all Files" })

-- Select all
vscode_map("n", "<C-a>", "editor.action.selectAll", { desc = "Select all" })

-- Indent/outdent
vscode_map("v", "<S-Tab>", "editor.action.outdentLines", { desc = "Outdent" })
vscode_map("v", "<Tab>", "editor.action.indentLines", { desc = "Indent" })

-- File explorer
vscode_map("n", "<leader>e", "workbench.view.explorer", { desc = "Open Explorer" })

-- Close a file
vscode_map("n", "<leader>bd", "workbench.action.closeActiveEditor", { desc = "Close file" })

vscode_map("n", "<leader>b", "workbench.action.toggleSidebarVisibility", { desc = "Toggle sidebar" })

vscode_map("n", "<leader>ff", "workbench.action.quickOpen", { desc = "Find files" })
vscode_map("n", "<leader>fr", "workbench.action.replaceInFiles", { desc = "Find and replace" })
vscode_map("n", "<leader>fg", "workbench.action.findInFiles", { desc = "Find and replace" })
vscode_map("n", "<leader>fw", "workbench.action.findInFiles", { desc = "Find in workspace" })
vscode_map("n", "<leader>fs", "workbench.action.gotoSymbol", { desc = "Find symbol in file" })
vscode_map("n", "<leader>fS", "workbench.action.showAllSymbols", { desc = "Find symbol in workspace" })

vscode_map("n", "gd", "editor.action.revealDefinition", { desc = "Go to definition" })
vscode_map("n", "gpd", "editor.action.peekDefinition", { desc = "Peek definition" })
vscode_map("n", "gr", "editor.action.goToReferences", { desc = "Go to references" })
vscode_map("n", "gi", "editor.action.goToImplementation", { desc = "Go to implementation" })

-- Go to next/previous diagnostics
vscode_map("n", "]d", "editor.action.marker.next", { desc = "Next diagnostic" })
vscode_map("n", "[d", "editor.action.marker.prev", { desc = "Previous diagnostic" })
vscode_map("n", "<leader>xx", "workbench.actions.view.problems", { desc = "Previous diagnostic" })

vscode_map("n", "K", "editor.action.showHover", { desc = "Show hover" })

-- Code action
vscode_map("n", "<leader>ca", "editor.action.codeAction", { desc = "Code action" })
vscode_map("n", "<leader>co", "editor.action.organizeImports", { desc = "Code action" })
vscode_map("n", "<leader>cr", "editor.action.rename", { desc = "Rename symbol" })
vscode_map("n", "<leader>cf", "editor.action.formatDocument", { desc = "Format document" })

-- Duplicate line
vscode_map("n", "<leader>j", "editor.action.copyLinesDownAction", { desc = "Duplicate line" })
vscode_map("v", "<leader>j", "editor.action.copyLinesDownAction", { desc = "Duplicate selection" })

-- Comment line
vscode_map({ "n", "x", "v" }, "<leader>/", function()
  vim.fn.VSCodeNotifyRange("editor.action.commentLine", vim.fn.line("v"), vim.fn.line("."), 1)
end)

-- Source control
vscode_map("n", "<leader>gg", "workbench.view.scm", { desc = "Source control" })

-- Search mode
map("n", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("n", "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous search result" })

-- Remove highlight after searching
map("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear search highlighting" })

-- Additional useful VSCode-specific commands
vscode_map("n", "<leader>t", "workbench.action.terminal.toggleTerminal", { desc = "Toggle terminal" })

-- Search in workspace
vscode_map("n", "<leader>ut", "workbench.action.togglePanel", { desc = "Toggle bottom panel" })
vscode_map("n", "<leader>ua", "workbench.action.toggleActivityBarVisibility", { desc = "Toggle activity bar" })
vscode_map("n", "<leader>un", "notifications.clearAll", { desc = "Clear all notifications" })
vscode_map("n", "<leader>uz", "workbench.action.toggleZenMode", { desc = "TOggle zen" })
vscode_map("n", "<leader>uc", "workbench.action.selectTheme", { desc = "Change colorscheme" })

vscode_map({ "v" }, "<leader>r", "editor.action.refactor", { desc = "Refactor" })

vim.keymap.set({ "n" }, "zr", function()
  vim.fn.VSCodeNotify("editor.unfoldAll")
end)
vim.keymap.set({ "n" }, "zO", function()
  vim.fn.VSCodeNotify("editor.unfoldRecursively")
end)
vim.keymap.set({ "n" }, "zo", function()
  vim.fn.VSCodeNotify("editor.unfold")
end)
vim.keymap.set({ "n" }, "zm", function()
  vim.fn.VSCodeNotify("editor.foldAll")
end)
vim.keymap.set({ "n" }, "zb", function()
  vim.fn.VSCodeNotify("editor.foldAllBlockComments")
end)
vim.keymap.set({ "n" }, "zc", function()
  vim.fn.VSCodeNotify("editor.fold")
end)
vim.keymap.set({ "n" }, "zg", function()
  vim.fn.VSCodeNotify("editor.foldAllMarkerRegions")
end)
vim.keymap.set({ "n" }, "zG", function()
  vim.fn.VSCodeNotify("editor.unfoldAllMarkerRegions")
end)
vim.keymap.set({ "n" }, "za", function()
  vim.fn.VSCodeNotify("editor.toggleFold")
end)
