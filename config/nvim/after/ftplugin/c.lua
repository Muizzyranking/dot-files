local bufnr = vim.api.nvim_get_current_buf()
vim.bo.shiftwidth = 8
vim.bo.tabstop = 8
vim.bo.softtabstop = 8
vim.bo.expandtab = false

vim.g.disable_autoformat = false
vim.b.disable_autoformat = false

if Utils.has("clangd_extensions.nvim") then
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    "<leader>ch",
    "<cmd>ClangdSwitchSourceHeader<cr>",
    { desc = "Switch Source/Header" }
  )
end

Utils.map({
  {
    "<F5>",
    function()
      Utils.runner.setup("c")
    end,
    icon = { icon = " ", color = "red" },
    desc = "Code runner",
    mode = "n",
    buffer = bufnr,
  },
})
