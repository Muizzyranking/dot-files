local function get_root()
  return Utils.find_root_directory(0, { ".git", "lua" })
end
return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false,
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
        config = function()
          Utils.on_load("telescope.nvim", function()
            pcall(require("telescope").load_extension, "fzf")
          end)
        end,
      },
    },
    keys = {
      {
        "<leader>fk",
        function()
          require("telescope.builtin").keymaps()
        end,
        desc = "Find Keymaps",
      },
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files({
            cwd = get_root(),
            layout_config = {
              preview_width = 0.6,
            },
          })
        end,
        desc = "Find Files (root)",
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").find_files({
            find_command = { "rg", "--files", "--hidden", "--no-ignore", "-g", "!.git" },
            cwd = get_root(),
            prompt_title = "Show all files",
            layout_config = {
              preview_width = 0.6,
            },
          })
        end,
        desc = "Find Files(hidden)",
      },
      {
        "<leader>sw",
        function()
          require("telescope.builtin").grep_string({
            layout_config = {
              preview_width = 0.6,
            },
          })
        end,
        desc = "Search word under cursor",
      },
      {
        "<leader>fg",
        function()
          require("telescope.builtin").live_grep({
            cwd = get_root(),
            layout_config = {
              preview_width = 0.6,
            },
          })
        end,
        desc = "Find by Grep (root)",
      },
      {
        "<leader>fG",
        function()
          require("telescope.builtin").live_grep({
            layout_config = {
              preview_width = 0.6,
            },
          })
        end,
        desc = "Find by Grep",
      },
      {
        "<leader>fC",
        function()
          require("telescope.builtin").resume({
            layout_config = {
              preview_width = 0.6,
            },
          })
        end,
        desc = "Search Continue",
      },
      {
        "<leader>fR",
        function()
          require("telescope.builtin").oldfiles({
            prompt_title = "Recent Files",
            layout_config = {
              preview_width = 0.6,
            },
          })
        end,
        desc = "Find Recent Files",
      },
      {
        "<leader>fr",
        function()
          require("telescope.builtin").oldfiles({
            only_cwd = true,
            cwd_only = true,
            prompt_title = "Recent Files in cwd",
            layout_config = {
              preview_width = 0.6,
            },
          })
        end,
        desc = "Find Recent Files (cwd)",
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers(require("telescope.themes").get_dropdown({
            winblend = 0,
            previewer = false,
          }))
        end,
        desc = "Find buffers",
      },

      { "<leader>,", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Find Buffers" },
      {
        "<leader>fm",
        function()
          require("telescope.builtin").man_pages()
        end,
        desc = "Find Man Pages",
      },
      {
        "<leader>:",
        function()
          require("telescope.builtin").command_history(require("telescope.themes").get_dropdown({
            winblend = 0,
            previewer = false,
          }))
        end,
        desc = "Command History",
      },
      {
        "<leader>uc",
        function()
          require("telescope.builtin").colorscheme({ enable_preview = true, ignore_builtins = true })
        end,
        desc = "colorscheme",
      },
      {
        "<leader>fw",
        function()
          require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
            winblend = 0,
            previewer = false,
          }))
        end,
        desc = "Find in Current Buffer",
      },
      {
        "<leader>fW",
        function()
          require("telescope.builtin").live_grep({
            grep_open_files = true,
            prompt_title = "Live Grep in Open Files",
            layout_config = {
              preview_width = 0.6,
            },
          })
        end,
        desc = "Find in Open Files",
      },
      {
        "<leader>fc",
        function()
          require("telescope.builtin").find_files({
            cwd = vim.fn.stdpath("config"),
            layout_config = {
              preview_width = 0.6,
            },
          })
        end,
        desc = "Find Config Files",
      },
    },
    opts = function()
      local actions = require("telescope.actions")
      return {
        defaults = {
          layout_strategy = "horizontal",
          layout_config = {
            prompt_position = "top",
          },
          sorting_strategy = "ascending",
          winblend = 0,
          mappings = {
            i = {
              ["<c-t>"] = require("trouble.sources.telescope").open,
              -- ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<C-d>"] = actions.delete_buffer,
              ["<C-c>"] = actions.close,
              -- ["<C-o>"] = actions.open_in_new_buffer,
              ["<C-o>"] = Utils.telescope.open_in_new_buffer,
            },
            n = {
              ["q"] = actions.close,
              ["<C-o>"] = Utils.telescope.open_in_new_buffer,
              ["<C-d>"] = actions.delete_buffer,
              ["<C-t>"] = require("trouble.sources.telescope").open,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-b>"] = actions.preview_scrolling_up,
            },
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local Keys = require("plugins.lsp.lspconfig.keymaps").get()
      vim.list_extend(Keys, {
        {
          "gd",
          function()
            require("telescope.builtin").lsp_definitions({ reuse_win = true })
          end,
          desc = "Goto Definition",
          has = "definition",
        },
        {
          "gD",
          function()
            require("telescope.builtin").lsp_definitions({
              jump_type = "vsplit",
            })
          end,
          desc = "Goto Definition (vsplit)",
          has = "definition",
        },
        {
          "gr",
          function()
            require("telescope.builtin").lsp_references()
          end,
          desc = "Goto References",
          has = "references",
        },
        {
          "gI",
          function()
            require("telescope.builtin").lsp_implementations({ reuse_win = true })
          end,
          desc = "Goto Implementation",
        },
        {
          "gy",
          function()
            require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
          end,
          desc = "Goto T[y]pe Definition",
        },
      })
    end,
  },
}
