return {
  "cbochs/grapple.nvim",
  event = "VeryLazy",
  opts = {
    scope = "lsp",
    default_scopes = {
      lsp = {
        name = "lsp",
        desc = "LSP root directory",
        fallback = "git",
        cache = {
          event = { "LspAttach", "LspDetach" },
          debounce = 250, -- ms
        },
        resolver = function()
          local clients = Utils.lsp.get_clients({ bufnr = Utils.ensure_buf(0) })
          if #clients == 0 then
            return
          end

          local path = clients[1].root_dir

          return path, path
        end,
      },
    },
    ---Values for which a buffer should be excluded from being tagged
    exclusions = {
      buftype = { "nofile" },
      filetype = { "grapple" },
      name = { ".env" },
    },

    statusline = {
      icon = "",
      inactive = " %s ",
      active = "[%s]",
      include_icon = true,
    },
  },
  config = function(_, opts)
    require("grapple").setup(opts)

    local function set_num_keys()
      for i = 1, 5 do
        pcall(function()
          vim.keymap.del("n", "<leader>m" .. i)
          Utils.map.hide_from_wk({ "<leader>m" .. i })
        end)
      end
      local num_keys = {}
      for i = 1, 5 do
        if require("grapple").exists({ index = i }) then
          table.insert(num_keys, {
            "<leader>m" .. i,
            function()
              require("grapple").select({ index = i })
            end,
            desc = "Goto bookmark " .. i,
          })
        end
      end

      if #num_keys > 0 then
        Utils.map.set_keymaps(num_keys, { icon = "󰓹 ", color = "green" })
      end
    end
    local function grapple_update_maps(method, options)
      options = options or {}
      method = method or "tag"
      local ok, result = pcall(function()
        require("grapple")[method](options)
        set_num_keys()
      end)
      if ok then
        return result
      end
    end
    Utils.map.add_to_wk({
      {
        "<leader>m",
        desc = "Bookmarks",
        icon = { icon = "󰓹 ", color = "green" },
      },
    })
    local keys = {
      {
        "<leader>mb",
        function()
          grapple_update_maps("tag")
        end,
        desc = "Bookmark file",
      },
      {
        "<leader>md",
        function()
          grapple_update_maps("untag")
        end,
        desc = "Remove bookmark",
        icon = { icon = "󰅖 ", color = "red" },
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
          grapple_update_maps("reset")
        end,
        desc = "Clear bookmarks",
        icon = { icon = " ", color = "red" },
      },
    }
    Utils.map.set_keymaps(keys, { icon = "󰓹 ", color = "green" })
    set_num_keys()
    Utils.autocmd("BufEnter", {
      callback = function()
        set_num_keys()
      end,
    })
  end,
}
