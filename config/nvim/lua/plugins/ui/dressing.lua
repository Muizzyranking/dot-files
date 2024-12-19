return {
  {
    "stevearc/dressing.nvim",
    keys = { "z=" },
    event = "UIEnter",
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
    config = function(_, opts)
      require("dressing").setup(opts)
      vim.keymap.set("n", "z=", function()
        local word = vim.fn.expand("<cword>")
        local suggestions = vim.fn.spellsuggest(word)
        vim.ui.select(
          suggestions,
          {},
          vim.schedule_wrap(function(selected)
            if selected then
              vim.cmd.normal({ args = { "ciw" .. selected }, bang = true })
            end
          end)
        )
      end)
    end,
  },
}
