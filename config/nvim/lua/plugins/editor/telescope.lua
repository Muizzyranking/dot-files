local function get_root()
  return Utils.find_root_directory(0, { ".git", "lua" })
end
return {
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
        require("telescope.builtin").find_files({ cwd = get_root() })
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
        })
      end,
      desc = "Find Files(hidden)",
    },
    {
      "<leader>sw",
      function()
        require("telescope.builtin").grep_string()
      end,
      desc = "Search word under cursor",
    },
    {
      "<leader>fg",
      function()
        require("telescope.builtin").live_grep({ cwd = get_root() })
      end,
      desc = "Find by Grep (root)",
    },
    {
      "<leader>fG",
      function()
        require("telescope.builtin").live_grep()
      end,
      desc = "Find by Grep",
    },
    {
      "<leader>fC",
      function()
        require("telescope.builtin").resume()
      end,
      desc = "Search Continue",
    },
    {
      "<leader>fR",
      function()
        require("telescope.builtin").oldfiles({ prompt_title = "Recent Files" })
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
        })
      end,
      desc = "Find Recent Files (cwd)",
    },
    { "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Find Buffers" },
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
        require("telescope.builtin").command_history()
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
        require("telescope.builtin").current_buffer_fuzzy_find(
          require("telescope.themes").get_dropdown({ winblend = 0, previewer = false })
        )
      end,
      desc = "Find in Current Buffer",
    },
    {
      "<leader>fW",
      function()
        require("telescope.builtin").live_grep({
          grep_open_files = true,
          prompt_title = "Live Grep in Open Files",
        })
      end,
      desc = "Find in Open Files",
    },
    {
      "<leader>fc",
      function()
        require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find Config Files",
    },
  },
  config = function()
    local actions = require("telescope.actions")
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

      if #selections > 0 and selections[#selections].filename then
        vim.cmd("buffer " .. vim.fn.fnameescape(selections[#selections].filename))
      end
    end

    require("telescope").setup({

      defaults = {
        -- layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          i = {
            ["<c-t>"] = require("trouble.sources.telescope").open,
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
    })
  end,
}
