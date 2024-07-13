local utils = require("utils")
local builtin = require("telescope.builtin")
return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  tag = "0.1.8",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
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
    { "nvim-tree/nvim-web-devicons" },
  },
  keys = {
    { "<leader>fk", builtin.keymaps, desc = "Find Keymaps" },
    { "<leader>ff", builtin.find_files, desc = "Find Files" },
    { "<leader>sw", builtin.grep_string, desc = "Search word under cursor" },
    { "<leader>fg", builtin.live_grep, desc = "Find by Grep" },
    { "<leader>fR", builtin.resume, desc = "Search Resume" },
    { "<leader>fr", builtin.oldfiles, desc = "Find Recent Files" },
    { "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Find Buffers" },
    { "<leader>,", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Find Buffers" },
    { "<leader>fm", builtin.man_pages, desc = "Find Man Pages" },
    { "<leader>:", builtin.command_history, desc = "Command History" },
    {
      "<leader>uc",
      function()
        builtin.colorscheme({ enable_preview = true })
      end,
      desc = "colorscheme",
    },
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
    local open_with_trouble = require("trouble.sources.telescope").open
    local action_state = require("telescope.actions.state")

    actions.open_in_new_buffer = function(prompt_bufnr)
      local picker = action_state.get_current_picker(prompt_bufnr)
      local selections = picker:get_multi_selection()

      if #selections == 0 then
        table.insert(selections, action_state.get_selected_entry())
      end

      actions.close(prompt_bufnr)

      for _, selection in ipairs(selections) do
        if selection.filename then
          vim.cmd("badd " .. vim.fn.fnameescape(selection.filename))
        end
      end

      -- Switch to the last added buffer
      if #selections > 0 and selections[#selections].filename then
        vim.cmd("buffer " .. vim.fn.fnameescape(selections[#selections].filename))
      end
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
            ["<C-o>"] = actions.open_in_new_buffer,
          },
          n = {
            ["q"] = actions.close,
            ["<C-o>"] = actions.open_in_new_buffer,
            ["<C-d>"] = actions.delete_buffer,
            ["<C-t>"] = open_with_trouble,
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
    })
  end,
}
