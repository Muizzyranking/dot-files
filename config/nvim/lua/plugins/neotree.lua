return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  event = "VeryLazy",
  keys = {
    {
      "<leader>E",
      function()
        if vim.bo.filetype == "neo-tree" then
          vim.cmd.Neotree("close")
        else
          vim.cmd.Neotree("float")
        end
      end,
      desc = "Float File Explorer",
    },
    {
      "<leader>e",
      function()
        if vim.bo.filetype == "neo-tree" then
          vim.cmd.Neotree("close")
        else
          vim.cmd.Neotree("toggle")
        end
      end,
      desc = "Left File Explorer",
    },
  },
  config = function()
    local icons = require("config.util").icons.neotree
    local git_available = vim.fn.executable("git") == 1
    -- local sources = {
    --   { source = "filesystem", display_name = icons.folder .. " " .. "Files" },
    --   { source = "buffers", display_name = icons.buffer .. " " .. "Buffers" },
    -- }
    -- if git_available then
    --   table.insert(sources, 3, { source = "git_status", display_name = icons.git .. " " .. "Git" })
    -- end
    require("neo-tree").setup({
      close_if_last_window = true,
      popup_border_style = "single",
      enable_git_status = git_available,
      -- sources = { "filesystem", "buffers", git_available and "git_status" or nil },
      -- source_selector = {
      --   winbar = true,
      --   content_layout = "center",
      --   -- tabs_layout = "equal",
      --   sources = sources,
      -- },
      enable_modified_markers = true,
      enable_diagnostics = true,
      sort_case_insensitive = true,
      default_component_configs = {
        indent = {
          with_markers = true,
          with_expanders = true,
        },
        modified = {
          symbol = " ",
          highlight = "NeoTreeModified",
        },
        git_status = {
          symbols = {
            -- Change type
            -- added = " ",
            -- deleted = " ",
            -- modified = " ",
            -- renamed = " ",
            -- Status type
            -- untracked = " ",
            -- ignored = " ",
            -- unstaged = " ",
            -- staged = " ",
            -- conflict = " ",
          },
        },
      },
      window = {
        position = "left",
        width = 40,
        mappings = {
          ["h"] = "prev_source",
          ["l"] = "next_source",
        },
      },
      filesystem = {
        use_libuv_file_watcher = true,
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        filtered_items = {
          hide_dotfiles = true,
          hide_gitignored = true,
          hide_by_name = {
            "node_modules",
          },
          never_show = {
            ".DS_Store",
            "thumbs.db",
          },
        },
      },
      event_handlers = {
        {
          event = "neo_tree_window_after_open",
          handler = function(args)
            if args.position == "left" or args.position == "right" then
              vim.cmd("wincmd =")
            end
          end,
        },
        {
          event = "neo_tree_window_after_close",
          handler = function(args)
            if args.position == "left" or args.position == "right" then
              vim.cmd("wincmd =")
            end
          end,
        },
      },
    })
  end,
}
