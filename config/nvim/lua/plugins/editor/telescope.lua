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
        Utils.telescope.pick("find_files", "wide_preview"),
        desc = "Find Files (root)",
      },
      {
        "<leader>fh",
        Utils.telescope.pick("find_files", "wide_preview", {
          find_command = { "rg", "--files", "--hidden", "--no-ignore", "-g", "!.git" },
          prompt_title = "Show all files",
        }),
        desc = "Find Files(hidden)",
      },
      {
        "<leader>sw",
        Utils.telescope.pick("grep_string", "wide_preview", { cwd = false }),
        desc = "Search word under cursor",
      },
      {
        "<leader>fg",
        Utils.telescope.pick("multi_grep", "wide_preview", {}),
        desc = "Find by Grep (root)",
      },
      {
        "<leader>fG",
        Utils.telescope.pick("multi_grep", "wide_preview", { cwd = false }),
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
        Utils.telescope.pick("oldfiles", "wide_preview", { cwd = false, prompt_title = "Recent Files" }),
        desc = "Find Recent Files",
      },
      {
        "<leader>fr",
        Utils.telescope.pick("oldfiles", "wide_preview", { cwd_only = true, prompt_title = "Recent Files in cwd" }),
        desc = "Find Recent Files (cwd)",
      },
      {
        "<leader>fb",
        Utils.telescope.pick("buffers", "dropdown"),
        desc = "Find buffers",
      },
      {
        "<leader>,",
        Utils.telescope.pick("buffers", "dropdown", { sort_mru = true, sort_lastused = true }),
        desc = "Find buffers",
      },
      {
        "<leader>fm",
        function()
          require("telescope.builtin").man_pages()
        end,
        desc = "Find Man Pages",
      },
      {
        "<leader>:",
        Utils.telescope.pick("command_history", "dropdown"),
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
        Utils.telescope.pick("current_buffer_fuzzy_find", "dropdown"),
        desc = "Find in Current Buffer",
      },
      {
        "<leader>fW",
        Utils.telescope.pick(
          "live_grep",
          "wide_preview",
          { grep_open_files = true, prompt_title = "Live Grep in Open Files" }
        ),
        desc = "Find in Open Files",
      },
      {
        "<leader>fc",
        Utils.telescope.pick(
          "find_files",
          "wide_preview",
          { cwd = vim.fn.stdpath("config"), prompt_title = "Find Config Files" }
        ),
        desc = "Find Config Files",
      },
    },
    opts = function()
      local actions = require("telescope.actions")
      return {
        defaults = {
          file_ignore_patterns = {},
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
              -- ["<C-o>"] = Utils.telescope.open_in_new_buffer,
              ["<CR>"] = Utils.telescope.open,
            },
            n = {
              ["q"] = actions.close,
              -- ["<C-o>"] = Utils.telescope.open_in_new_buffer,
              ["<C-d>"] = actions.delete_buffer,
              ["<C-t>"] = require("trouble.sources.telescope").open,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-b>"] = actions.preview_scrolling_up,
              ["<CR>"] = Utils.telescope.open,
            },
          },
        },
        extensions = {},
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
          Utils.telescope.pick("lsp_definitions", "wide_preview", { reuse_win = true }),
          desc = "Goto Definition",
          has = "definition",
        },
        {
          "gD",
          Utils.telescope.pick("lsp_definitions", "wide_preview", {
            jump_type = "vsplit",
            reuse_win = true,
          }),
          desc = "Goto Definition (vsplit)",
          has = "definition",
        },
        {
          "gr",
          Utils.telescope.pick("lsp_references", "wide_preview", { reuse_win = true }),
          desc = "Goto References",
          has = "references",
        },
        {
          "gI",
          Utils.telescope.pick("lsp_implementations", "wide_preview", { reuse_win = true }),
          desc = "Goto Implementation",
        },
        {
          "gT",
          function()
            require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
          end,
          desc = "Goto Type Definition",
        },
      })
    end,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      disable_ft = { "TelescopePrompt" },
    },
  },
}
