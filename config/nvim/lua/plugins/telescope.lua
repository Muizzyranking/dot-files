local utils = require("utils")
local builtin = require("telescope.builtin")
return { -- Fuzzy Finder (files, lsp, etc)
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { -- If encountering errors, see telescope-fzf-native README for install instructions
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
      config = function()
        utils.on_load("telescope.nvim", function()
          pcall(require("telescope").load_extension, "fzf")
        end)
      end,
    },
    {
      -- project management
      {
        "ahmedkhalf/project.nvim",
        opts = {
          manual_mode = true,
        },
        event = "VeryLazy",
        config = function(_, opts)
          require("project_nvim").setup(opts)
          utils.on_load("telescope.nvim", function()
            require("telescope").load_extension("projects")
          end)
        end,
        keys = {
          { "<leader>fp", "<Cmd>Telescope projects<CR>", desc = "Projects" },
        },
      },
    },
    { "nvim-tree/nvim-web-devicons" },
  },
  keys = {
    { "<leader>fh", builtin.help_tags, desc = "Find Help Tags" },
    { "<leader>fk", builtin.keymaps, desc = "Find Keymaps" },
    { "<leader>ff", builtin.find_files, desc = "Find Files" },
    -- map("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
    { "<leader>sw", builtin.grep_string, desc = "Search word under cursor" },
    { "<leader>fg", builtin.live_grep, desc = "Find by Grep" },
    { "<leader>fd", builtin.diagnostics, desc = "Find Diagnostics" },
    { "<leader>fR", builtin.resume, desc = "Search Resume" },
    { "<leader>fr", builtin.oldfiles, desc = "Find Recent Files" },
    -- { "<leader>fb", builtin.buffers, desc = "Find Buffers" },
    { "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Find Buffers" },
    { "<leader>,", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Find Buffers" },
    { "<leader>fm", builtin.man_pages, desc = "Find Man Pages" },
    { "<leader>:", builtin.command_history, desc = "Command History" },
    -- { "<leader>gs", builtin.git_status, desc = "Git Status (Telescope)" },
    { "<leader>gC", builtin.git_commits, desc = "Git Commit (Telescope)" },
    { "<leader>gf", builtin.git_files, desc = "Git files (Telescope)" },
    {
      "<leader>fw",
      function()
        builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 0,
          previewer = false,
        }))
      end,
      desc = "Find in Current Buffer",
    },
    {
      "<leader>fW",
      function()
        builtin.live_grep({
          grep_open_files = true,
          prompt_title = "Live Grep in Open Files",
        })
      end,
      desc = "Find in Open Files",
    },
    {
      "<leader>fc",
      function()
        builtin.find_files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find Config Files",
    },
  },
  config = function()
    local actions = require("telescope.actions")
    local open_with_trouble = function(...)
      return require("trouble.providers.telescope").open_with_trouble(...)
    end

    require("telescope").setup({

      -- You can put your default mappings / updates / etc. in here
      defaults = {
        -- layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          i = {
            ["<c-t>"] = open_with_trouble,
            -- ["<C-f>"] = actions.preview_scrolling_down,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.delete_buffer,
            ["<C-c>"] = actions.close,
          },
          n = {
            ["q"] = actions.close,
            ["<C-d>"] = actions.delete_buffer,
            ["<C-t>"] = open_with_trouble,
            ["<C-f>"] = actions.preview_scrolling_down,
            ["<C-b>"] = actions.preview_scrolling_up,
          },
        },
      },
      -- pickers = {}
      -- extensions = {
      --   ["ui-select"] = {
      --     require("telescope.themes").get_dropdown(),
      --   },
      -- },
    })
  end,
}
