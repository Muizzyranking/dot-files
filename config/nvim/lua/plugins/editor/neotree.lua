return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  keys = {
    {
      "<leader>E",
      "<cmd>Neotree toggle<cr>",
      desc = "File Explorer",
    },
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({
          toggle = true,
          reveal_force_cwd = true,
        })
      end,
      desc = "File Explorer",
    },
  },
  opts = function()
    vim.api.nvim_create_autocmd("TermClose", {
      pattern = "*lazygit",
      callback = function()
        if package.loaded["neo-tree.sources.git_status"] then
          require("neo-tree.sources.git_status").refresh()
        end
      end,
    })
    return {
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
      sources = { "filesystem", "buffers", "git_status" },
      close_if_last_window = true,
      popup_border_style = "single",
      enable_git_status = true,
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
            conflict = " ",
          },
        },
      },
      window = {
        position = "right",
        width = 40,
        mappings = {
          ["l"] = "open",
          ["h"] = "close_node",
          ["<space>"] = "none",
          ["Y"] = {
            function(state)
              local node = state.tree:get_node()
              local path = node:get_id()
              vim.fn.setreg("+", path, "c")
            end,
            desc = "Copy Path to Clipboard",
          },
          ["O"] = {
            function(state)
              require("lazy.util").open(state.tree:get_node().path, { system = true })
            end,
            desc = "Open with System Application",
          },
          ["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = false } },
          ["<C-b>"] = { "scroll_preview", config = { direction = 10 } },
          ["<C-f>"] = { "scroll_preview", config = { direction = -10 } },
          ["T"] = { "trash" },
        },
      },
      filesystem = {
        commands = {
          -- Override delete to use trash instead of rm
          trash = function(state)
            if Utils.is_executable("trash") then
              local node = state.tree:get_node()
              if node.type == "message" then
                return
              end
              local _, name = require("neo-tree.utils").split_path(node.path)
              local msg = string.format("Are you sure you want to trash '%s'?", name)
              require("neo-tree.ui.inputs").confirm(msg, function(confirmed)
                if not confirmed then
                  return
                end
                vim.api.nvim_command("silent !trash -F " .. node.path)
                require("neo-tree.sources.manager").refresh(state)
              end)
            end
          end,
        },
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
          always_show_by_pattern = {
            ".zsh*",
          },
        },
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.cmd("setlocal signcolumn=no")
            if Utils.has("nvim-notify") then
              require("notify").dismiss({ silent = true, pending = true })
            end
          end,
        },
        {
          event = "file_moved",
          handler = function(data)
            Utils.lsp.on_rename_file(data.source, data.destination)
          end,
        },
        {
          event = "file_renamed",
          handler = function(data)
            Utils.lsp.on_rename_file(data.source, data.destination)
          end,
        },
      },
    }
  end,
}
