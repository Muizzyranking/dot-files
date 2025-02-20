return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        prompt = " ",
        sources = {
          files = {
            exclude = { ".git", ".cache" },
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
        previewers = {
          file = {
            max_size = vim.g.big_file,
            max_line_length = vim.g.max_lines,
          },
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
        win = {
          input = {
            keys = {
              ["<a-c>"] = {
                "toggle_cwd",
                mode = { "n", "i" },
              },
              ["/"] = "toggle_focus",
              ["<C-bs>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
              ["<C-h>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
            },
          },
          list = {
            keys = {
              ["/"] = "toggle_focus",
            },
          },
        },
        actions = {
          toggle_cwd = function(p)
            local root = Utils.root({ buf = p.input.filter.current_buf })
            local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
            local current = p:cwd()
            p:set_cwd(current == root and cwd or root)
            p:find()
          end,
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
        "<leader>fB",
        function()
          Snacks.picker.buffers({ hidden = true, nofile = true })
        end,
        desc = "Buffers (all)",
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
        "<leader>ff",
        function()
          Snacks.picker.files({
            cwd = Utils.root(),
          })
        end,
        desc = "Find Files (Root Dir)",
      },
      {
        "<leader>fF",
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
        "<leader>fW",
        function()
          Snacks.picker.grep_buffers()
        end,
        desc = "Grep in Open Buffers",
      },
      {
        "<leader>fw",
        function()
          Snacks.picker.lines({ layout = { preset = "drop" } })
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
      {
        "<leader>sh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help Pages",
      },
      {
        "<leader>sH",
        function()
          Snacks.picker.highlights()
        end,
        desc = "Highlights",
      },
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
          Snacks.picker.keymaps({ layout = { preset = "dropdown", preview = false } })
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
    "folke/flash.nvim",
    optional = true,
    specs = {
      {
        "folke/snacks.nvim",
        opts = {
          picker = {
            win = {
              input = {
                keys = {
                  ["<a-s>"] = { "flash", mode = { "n", "i" } },
                  ["s"] = { "flash" },
                },
              },
            },
            actions = {
              flash = function(picker)
                require("flash").jump({
                  pattern = "^",
                  label = { after = { 0, 0 } },
                  search = {
                    mode = "search",
                    exclude = {
                      function(win)
                        return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                      end,
                    },
                  },
                  action = function(match)
                    local idx = picker.list:row2idx(match.pos[1])
                    picker.list:_move(idx, true, true)
                  end,
                })
              end,
            },
          },
        },
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
    "saghen/blink.cmp",
    optional = true,
    opts = {
      disable_ft = { "snacks_picker_input" },
    },
  },
}
