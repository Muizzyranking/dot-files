return { -- Fuzzy Finder (files, lsp, etc)
  "nvim-telescope/telescope.nvim",
  event = "VimEnter",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { -- If encountering errors, see telescope-fzf-native README for install instructions
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    { "nvim-telescope/telescope-ui-select.nvim" },

    { "nvim-tree/nvim-web-devicons" },
  },
  config = function()
    local builtin = require("telescope.builtin")
    local map = function(key, action, desc)
      vim.keymap.set("n", key, action, { desc = desc })
    end
    local actions = require("telescope.actions")
    local trouble = require("trouble.providers.telescope")

    require("telescope").setup({

      -- You can put your default mappings / updates / etc. in here
      defaults = {
        -- layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          i = {
            ["<c-t>"] = trouble.open_with_trouble,
            ["<C-f>"] = actions.preview_scrolling_down,
            ["<C-b>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.delete_buffer,
            ["<C-c>"] = actions.close,
          },
          n = {
            ["q"] = actions.close,
            ["<C-d>"] = actions.delete_buffer,
            ["<C-t>"] = trouble.open_with_trouble,
            ["<C-f>"] = actions.preview_scrolling_down,
            ["<C-b>"] = actions.preview_scrolling_up,
          },
        },
      },
      -- pickers = {}
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
      },
    })

    -- Enable telescope extensions, if they are installed
    pcall(require("telescope").load_extension, "fzf")
    pcall(require("telescope").load_extension, "ui-select")
    local new_file = require("config.functions").new_file

    map("<leader>fn", new_file, "Create new file")
    map("<leader>fh", builtin.help_tags, "Find Help Tags")
    map("<leader>fk", builtin.keymaps, "Find Keymaps")
    map("<leader>ff", builtin.find_files, "Find Files")
    -- map("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
    map("<leader>sw", builtin.grep_string, "Search word under cursor")
    map("<leader>fg", builtin.live_grep, "Find by Grep")
    map("<leader>fd", builtin.diagnostics, "Find Diagnostics")
    map("<leader>fR", builtin.resume, "Search Resume")
    map("<leader>fr", builtin.oldfiles, "Find Recent Files")
    -- map("<leader>fb", builtin.buffers, "Find Buffers")
    map("<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", "Find Buffers")
    map("<leader>fm", builtin.man_pages, "Find Man Pages")
    map("<leader>:", builtin.command_history, "Command History")

    map("<leader>gs", builtin.git_status, "Git Status (Telescope)")
    map("<leader>gc", builtin.git_commits, "Git Commit (Telescope)")
    map("<leader>gf", builtin.git_files, "Git files (Telescope)")

    vim.keymap.set("n", "<leader>fw", function()
      builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
        winblend = 0,
        previewer = false,
      }))
    end, { desc = "Find in Current Buffer" })

    -- Also possible to pass additional configuration options.
    --  See `:help telescope.builtin.live_grep()` for information about particular keys
    vim.keymap.set("n", "<leader>fW", function()
      builtin.live_grep({
        grep_open_files = true,
        prompt_title = "Live Grep in Open Files",
      })
    end, { desc = "Find in Open Files" })

    -- Shortcut for searching your neovim configuration files
    vim.keymap.set("n", "<leader>fc", function()
      builtin.find_files({ cwd = vim.fn.stdpath("config") })
    end, { desc = "Find Config Files" })
  end,
}
