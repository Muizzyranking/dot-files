vim.bo.shiftwidth = 2
vim.bo.tabstop = 2

Utils.map.create_abbrevs({
  { "function", { "Function" } },
  { "local", { "loc", "Local" } },
  { "require", { "req", "Require" } },
  { "return", { "ret", "Return" } },
}, {
  buffer = true,
  conds = { "lsp_keyword" },
})

Utils.map.set_keymaps({
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
    buffer = true,
  },
})

Utils.root.add_patterns({ "lua", "stylua.toml" })
