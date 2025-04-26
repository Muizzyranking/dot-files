return {
  "cbochs/grapple.nvim",
  dependencies = {},
  keys = function()
    local keys = {
      {
        "<leader>m",
        desc = "Grapple: Toggle bookmark",
      },
      {
        "<leader>mb",
        function()
          require("grapple").tag()
        end,
        desc = "Bookmark file",
      },
      {
        "<leader>md",
        function()
          require("grapple").untag()
        end,
        desc = "Remove bookmark",
      },
      {
        "<leader>ml",
        function()
          require("plugins.editor.grapple.snacks").picker.show_bookmarks()
        end,
        desc = "Show bookmarks",
      },
      {
        "<leader>mc",
        function()
          require("grapple").reset()
        end,
        desc = "Clear bookmarks",
      },
    }
    for i = 1, 5 do
      table.insert(keys, {
        "<leader>m" .. i,
        function()
          if require("grapple").exists({ index = i }) then
            require("grapple").select({ index = i })
          end
        end,
        desc = "Goto bookmark " .. i,
      })
    end
    return keys
  end,
  opts = {},
}
