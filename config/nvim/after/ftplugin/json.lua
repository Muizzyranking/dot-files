local buf = Utils.ensure_buf(0)
Utils.map.set_keymaps({
  {
    "o",
    function()
      local line = vim.api.nvim_get_current_line()

      local should_add_comma = string.find(line, "[^,{[]$")
      if should_add_comma then
        return "A,<cr>"
      else
        return "o"
      end
    end,
    expr = true,
    buffer = buf,
  },
})

vim.bo[buf].shiftwidth = 2
vim.bo[buf].tabstop = 2
