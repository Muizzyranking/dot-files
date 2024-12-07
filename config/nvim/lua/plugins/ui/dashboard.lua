local dashboard = {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  opts = function()
    local opts = {
      theme = "doom",
      hide = {
        -- this is taken care of by lualine
        -- enabling this messes up the actual laststatus setting after loading a file
        statusline = false,
      },
      config = {
        -- header = vim.split(logo, "\n"),
        center = {
          {
            action = function()
              Utils.keys.new_file()
            end,
            desc = " New file",
            icon = " ",
            key = "n",
          },
          {
            -- action = "Telescope oldfiles",
            action = function()
              require("telescope.builtin").oldfiles({
                prompt_title = "Recent Files",
                layout_config = {
                  preview_width = 0.6,
                },
              })
            end,
            desc = " Recent files",
            icon = " ",
            key = "R",
          },
          {
            action = function()
              require("telescope.builtin").oldfiles({
                prompt_title = "Recent Files in current working directory",
                cwd_only = true,
                layout_config = {
                  preview_width = 0.6,
                },
              })
            end,
            desc = " Recent files (cwd)",
            icon = " ",
            key = "r",
          },
          {
            action = function()
              require("telescope.builtin").find_files({
                cwd = Utils.find_root_directory(0, { ".git", "lua" }),
                layout_config = {
                  preview_width = 0.6,
                },
              })
            end,
            desc = " Find files",
            icon = " ",
            key = "f",
          },
          {
            action = 'lua require("persistence").load()',
            desc = " Restore Session",
            icon = " ",
            key = "s",
          },
          {
            action = function()
              require("telescope.builtin").find_files({
                cwd = vim.fn.stdpath("config"),
                prompt_title = "Config Files",
                layout_config = {
                  preview_width = 0.6,
                },
              })
            end,
            desc = " Config",
            icon = " ",
            key = "c",
          },
          {
            action = "Lazy",
            desc = " Lazy",
            icon = "󰒲 ",
            key = "l",
          },
          {
            action = "qa",
            desc = " Quit",
            icon = " ",
            key = "q",
          },
        },
        footer = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
        end,
      },
    }

    for _, button in ipairs(opts.config.center) do
      button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
      button.key_format = "  %s"
    end

    -- close Lazy and re-open when the dashboard is ready
    if vim.o.filetype == "lazy" then
      vim.cmd.close()
      vim.api.nvim_create_autocmd("User", {
        pattern = "DashboardLoaded",
        callback = function()
          require("lazy").show()
        end,
      })
    end

    return opts
  end,
}
return {}
