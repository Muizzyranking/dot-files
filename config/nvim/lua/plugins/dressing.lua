return {
  {
    "stevearc/dressing.nvim",
    keys = { "z=" },
    event = "UIEnter",
    -- config = function(_, opts)
    --   require("dressing").setup(opts)
    --   vim.keymap.set("n", "z=", function()
    --     local word = vim.fn.expand("<cword>")
    --     local suggestions = vim.fn.spellsuggest(word)
    --     vim.ui.select(
    --       suggestions,
    --       {},
    --       vim.schedule_wrap(function(selected)
    --         if selected then
    --           vim.cmd.normal({ args = { "ciw" .. selected }, bang = true })
    --         end
    --       end)
    --     )
    --   end)
    -- end,
  },
}
