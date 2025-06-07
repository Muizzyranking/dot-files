return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.dashboard = {
      preset = {
        header = Utils.ui.logo.one,
        keys = {
          {
            icon = " ",
            key = "n",
            desc = "New File",
            action = function()
              vim.cmd("enew")
            end,
          },
          {
            icon = " ",
            key = "f",
            desc = "Find File",
            action = function()
              Snacks.picker.files({ cwd = Utils.root() })
            end,
          },
          {
            icon = " ",
            key = "g",
            desc = "Find Text",
            action = function()
              Snacks.picker.grep()
            end,
          },
          {
            icon = " ",
            key = "r",
            desc = "Recent Files",
            action = function()
              Snacks.picker.recent()
            end,
          },
          {
            icon = " ",
            key = "R",
            desc = "Recent Files (cwd)",
            action = function()
              Snacks.picker.recent({ filter = { cwd = true } })
            end,
          },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = function()
              Snacks.picker.files({ cwd = vim.fn.stdpath("config"), title = "Find Config Files" })
            end,
          },
          {
            icon = " ",
            key = "s",
            desc = "Restore Session",
            section = "session",
          },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        function()
          local plugin_stats = Utils.plugin_stats()
          local date = os.date("%d.%m.%Y")
          local updates = plugin_stats.updates > 0 and "  " .. plugin_stats.updates .. "" or ""
          return {
            align = "center",
            text = {
              { " ", hl = "footer" },
              { Utils.nvim_version(), hl = "footer" },
              { "    ", hl = "footer" },
              { tostring(plugin_stats.count), hl = "footer" },
              { updates, hl = "special" },
              { "   󰛕 ", hl = "footer" },
              { plugin_stats.startuptime .. " ms", hl = "special" },
              { "    ", hl = "footer" },
              { date, hl = "constant" },
            },
            padding = 1,
          }
        end,
        -- { section = "startup" },
      },
    }
    Utils.autocmd.on_user_event({ "LazyCheck", "LazyUpdate" }, function(event)
      if event.buf == "snacks_dashboard" then
        Snacks.dashboard.update()
      end
    end)
  end,
}
