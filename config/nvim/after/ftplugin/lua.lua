local buf = Utils.fn.ensure_buf(0)
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.b.autoformat = true

Utils.map.abbrev({
  { "function", { "Function" } },
  { "local", { "loc", "Local" } },
  { "require", { "req", "Require" } },
}, {
  buffer = buf,
  conds = { "lsp_keyword" },
})

Utils.map.set({
  {
    "<leader>sh",
    function()
      local word = vim.fn.expand("<cword>")
      local ok, _ = pcall(vim.cmd, "help " .. word)
      if not ok then
        Utils.notify.warn("No help found for: " .. word)
        Snacks.picker.help()
      end
    end,
    desc = "Show help",
    icon = { icon = "󰞋 ", color = "blue" },
    buffer = buf,
  },
})
