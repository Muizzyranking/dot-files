return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    -- event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    event = { "LazyFile", "VeryLazy" },
    init = function(plugin)
      -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
      -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
      -- no longer trigger the **nvim-treesitter** module to be loaded in time.
      -- Luckily, the only things that those plugins need are the custom queries, which we make available
      -- during startup.
      require("lazy.core.loader").add_to_rtp(plugin)
      require("nvim-treesitter.query_predicates")
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      {
        "windwp/nvim-ts-autotag",
        -- event = "LazyFile",
        -- opts = {},
      },
    },
    opts = {
      textobjects = {
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            ["]f"] = "@function.outer",
            ["]c"] = "@class.outer",
            ["]l"] = "@loop.*",
          },
          goto_next_end = {
            ["]F"] = "@function.outer",
            ["]C"] = "@class.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[c"] = "@class.outer",
          },
          goto_previous_end = {
            ["[F"] = "@function.outer",
            ["[C"] = "@class.outer",
          },
          goto_next = {
            ["]o"] = "@conditional.outer",
          },
          goto_previous = {
            ["[o"] = "@conditional.outer",
          },
        },
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<cr>",
          node_incremental = "<cr>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
      ensure_installed = {
        "c",
        "cpp",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "luadoc",
        "python",
        "toml",
        "ninja",
        "rst",
        "html",
        "htmldjango",
        "css",
        "javascript",
        "sql",
        "rst",
        "json",
        "json5",
        "jsonc",
        "markdown",
        "markdown_inline",
        "typescript",
        "tsx",
        "regex",
        "yaml",
        "bash",
        "diff",
        "jsdoc",
        "luadoc",
        "luap",
        "vim",
        "xml",
        "puppet",
        "hyprlang",
        "rasi",
      },

      -- Install parsers synchronously (only applied to `ensure_installed`)
      sync_install = false,

      -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
      auto_install = false,

      indent = { true },
      auto_tag = { true },

      highlight = {
        enable = true,

        -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,

        additional_vim_regex_highlighting = false,
      },
    },
    config = function(_, opts)
      vim.filetype.add({
        extension = { rasi = "rasi", rofi = "rasi", wofi = "rasi" },
        filename = {
          ["vifmrc"] = "vim",
        },
        pattern = {
          [".*/waybar/config"] = "jsonc",
          [".*/mako/config"] = "dosini",
          [".*/kitty/.+%.conf"] = "bash",
          [".*/hypr/.+%.conf"] = "hyprlang",
          ["%.env%.[%w_.-]+"] = "sh",
        },
      })
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  -- treesitter context
  -- {
  --   "nvim-treesitter/nvim-treesitter-context",
  --   event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
  --   -- enabled = true,
  --   opts = { mode = "cursor", max_lines = 3 },
  --   keys = {
  --     {
  --       "<leader>ut",
  --       function()
  --         local tsc = require("treesitter-context")
  --         local utils = require("config.util")
  --         tsc.toggle()
  --         if utils.get_upvalue(tsc.toggle, "enabled") then
  --           utils.info("Enabled Treesitter Context", { title = "Option" })
  --         else
  --           utils.warn("Disabled Treesitter Context", { title = "Option" })
  --         end
  --       end,
  --       desc = "Toggle Treesitter Context",
  --     },
  --   },
  -- },

  {
    "windwp/nvim-ts-autotag",
    event = "LazyFile",
    opts = {},
  },
}
