return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        prompt = " ",
        ui_select = true,
        sources = {
          files = {
            exclude = { ".git", ".cache" },
            actions = {
              bookmark = require("plugins.editor.grapple.snacks").picker.actions.bookmark,
            },
            win = {
              input = {
                keys = {
                  ["<c-b>"] = { "bookmark", mode = { "i", "n" }, desc = "Bookmark files" },
                },
              },
              list = {
                keys = {
                  ["<c-b>"] = { "bookmark", desc = "Bookmark files" },
                },
              },
            },
          },
          buffers = {
            sort_lastused = true,
            hidden = false,
            ignore_filetype = {},
            win = {
              input = {
                keys = {
                  ["dd"] = "bufdelete",
                  ["<c-x>"] = { "bufdelete", mode = { "n", "i" } },
                },
              },
              list = { keys = { ["dd"] = "bufdelete" } },
            },
            layout = { preset = "drop", preview = false },
          },
        },
        focus = "input",
        matcher = {
          fuzzy = true,
          frecency = true,
          history_bonus = true,
        },
        jump = {
          reuse_win = true,
          match = false,
        },
        layouts = {
          drop = {
            layout = {
              preview = false,
              backdrop = false,
              width = 0.4,
              min_width = 80,
              height = 0.6,
              border = "none",
              box = "vertical",
              { win = "preview", title = "{preview}", height = 0.4, border = "rounded" },
              {
                box = "vertical",
                border = "rounded",
                title = "{title} {live} {flags}",
                title_pos = "center",
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
              },
            },
          },
          code = {
            preview = false,
            layout = {
              backdrop = false,
              row = math.floor((vim.o.lines - (math.floor(vim.o.lines * 0.8))) / 2),
              width = 0.4,
              min_width = 80,
              height = 0.4,
              border = "none",
              box = "vertical",
              { win = "input", height = 1, border = "rounded", title = "{title} {live} {flags}", title_pos = "center" },
              { win = "list", border = "hpad" },
              { win = "preview", title = "{preview}", border = "rounded" },
            },
          },
        },
        actions = {},
        win = {
          input = {
            keys = {
              ["<C-h>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
            },

            b = {
              completion = false,
            },
          },
          list = {
            keys = {},
          },
        },
      },
    },
    keys = {
      {
        "z=",
        function()
          Snacks.picker.spelling()
        end,
        desc = "Spell suggestions",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history({ layout = { preset = "code" } })
        end,
        desc = "Command History",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("config"), title = "Find Config Files" })
        end,
        desc = "Find Config File",
      },
      {
        "<leader>fF",
        function()
          Snacks.picker.files({ cwd = Utils.root() })
        end,
        desc = "Find Files (Root Dir)",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files (cwd)",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>sw",
        function()
          Snacks.picker.grep_word()
        end,
        mode = { "n", "x" },
        desc = "Search word",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent files",
      },
      {
        "<leader>fR",
        function()
          Snacks.picker.recent({ filter = { cwd = true } })
        end,
        desc = "Recent files (cwd)",
      },
      {
        "<leader>fp",
        function()
          Snacks.picker.projects({ layout = { preview = false, preset = "drop" } })
        end,
        desc = "Projects",
      },
      {
        "<leader>fG",
        function()
          Snacks.picker.grep_buffers()
        end,
        desc = "Grep in Open Buffers",
      },
      {
        '<leader>f"',
        function()
          Snacks.picker.registers()
        end,
        desc = "Registers",
      },
      {
        "<leader>fd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      -- {
      --   "<leader>sh",
      --   function()
      --     Snacks.picker.help()
      --   end,
      --   desc = "Help Pages",
      -- },
      {
        "<leader>si",
        function()
          Snacks.picker.icons()
        end,
        desc = "Icons",
      },
      {
        "<leader>sk",
        function()
          Snacks.picker.keymaps({ layout = { preset = "drop", preview = false } })
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sm",
        function()
          Snacks.picker.man()
        end,
        desc = "Man Pages",
      },
      {
        "<leader>fC",
        function()
          Snacks.picker.resume()
        end,
        desc = "Continue from last search",
      },
      {
        "<leader>uc",
        function()
          Snacks.picker.colorschemes({
            layout = { preset = "select", preview = "colorscheme" },
          })
        end,
        desc = "Colorschemes",
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    optional = true,
    keys = {
      {
        "<leader>st",
        function()
          Snacks.picker.todo_comments()
        end,
        desc = "Todo",
      },
      {
        "<leader>sT",
        function()
          Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
        end,
        desc = "Todo/Fix/Fixme",
      },
    },
  },
  {
    "folke/trouble.nvim",
    optional = true,
    specs = {
      "folke/snacks.nvim",
      opts = function(_, opts)
        return vim.tbl_deep_extend("force", opts or {}, {
          picker = {
            actions = require("trouble.sources.snacks").actions,
            win = {
              input = {
                keys = {
                  ["<c-t>"] = {
                    "trouble_open",
                    mode = { "n", "i" },
                  },
                },
              },
            },
          },
        })
      end,
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>f", group = "file/find" },
      },
    },
  },
}
