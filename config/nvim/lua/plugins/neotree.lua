return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    {
      "<leader>e",
      "<cmd>Neotree toggle<cr>",
      desc = "File Explorer",
    },
  },
  config = function()
    local utils = require("utils")
    local git_available = vim.fn.executable("git") == 1
    require("neo-tree").setup({
      close_if_last_window = true,
      popup_border_style = "single",
      enable_git_status = git_available,
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
            conflict = " ",
          },
        },
      },
      window = {
        position = "right",
        width = 40,
        mappings = {
          ["h"] = "close_all_subnodes",
          ["l"] = "expand_all_nodes",
          ["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = false } },
          ["<C-b>"] = { "scroll_preview", config = { direction = 10 } },
          ["<C-f>"] = { "scroll_preview", config = { direction = -10 } },
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
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.cmd("setlocal signcolumn=no")
            if utils.has("nvim-notify") then
              require("notify").dismiss({ silent = true, pending = true })
            end
          end,
        },
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
    vim.api.nvim_create_autocmd("TermClose", {
      pattern = "*lazygit",
      callback = function()
        if package.loaded["neo-tree.sources.git_status"] then
          require("neo-tree.sources.git_status").refresh()
        end
      end,
    })
  end,
}
