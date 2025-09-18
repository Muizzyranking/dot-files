return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    branch = "main",
    build = ":TSUpdate",
    lazy = vim.fn.argc(-1) == 0,
    event = { "LazyFile", "VeryLazy" },
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    dependencies = {},
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "c",
        "cpp",
        "vim",
        "vimdoc",
        "query",
        "python",
        "toml",
        "rst",
        "regex",
        "yaml",
        "diff",
        "jsdoc",
        "luadoc",
        "luap",
        "vim",
        "xml",
        "puppet",
      },
    },
    config = function(_, opts)
      local ts = require("nvim-treesitter")
      if not Utils.is_executable("tree-sitter") then
        return Utils.notify.error({
          "**treesitter-main** requires the `tree-sitter` CLI executable to be installed.",
        })
      end
      ts.setup()
      local install = vim.tbl_filter(function(lang)
        return not Utils.ts.have(lang)
      end, opts.ensure_installed or {})
      if #install > 0 then
        ts.install(install, { summary = true }):await(function()
          Utils.ts.get_installed(true)
        end)
      end

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          if not vim.b[ev.buf].bigfile and Utils.ts.have(ev.match) then pcall(vim.treesitter.start) end
        end,
      })
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    event = "LazyFile",
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    opts = {},
    keys = function()
      local moves = {
        goto_next_start = {
          ["]f"] = "@function.outer",
          ["]c"] = "@class.outer",
          ["]a"] = "@parameter.inner",
        },
        goto_next_end = {
          ["]F"] = "@function.outer",
          ["]C"] = "@class.outer",
          ["]A"] = "@parameter.inner",
        },
        goto_previous_start = {
          ["[f"] = "@function.outer",
          ["[c"] = "@class.outer",
          ["[a"] = "@parameter.inner",
        },
        goto_previous_end = {
          ["[F"] = "@function.outer",
          ["[C"] = "@class.outer",
          ["[A"] = "@parameter.inner",
        },
        goto_next = {
          ["]o"] = "@conditional.outer",
        },
        goto_previous = {
          ["[o"] = "@conditional.outer",
        },
      }
      local ret = {} ---@type LazyKeysSpec[]
      for method, keymaps in pairs(moves) do
        for key, query in pairs(keymaps) do
          local desc = query:gsub("@", ""):gsub("%..*", "")
          desc = desc:sub(1, 1):upper() .. desc:sub(2)
          desc = (key:sub(1, 1) == "[" and "Prev " or "Next ") .. desc
          desc = desc .. (key:sub(2, 2) == key:sub(2, 2):upper() and " End" or " Start")
          ret[#ret + 1] = {
            key,
            function()
              if vim.wo.diff and key:find("[cC]") then return vim.cmd("normal! " .. key) end
              require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
            end,
            desc = desc,
            mode = { "n", "x", "o" },
            silent = true,
          }
        end
      end
      return ret
    end,
    config = function(_, opts)
      require("nvim-treesitter-textobjects").setup(opts)
    end,
  },
}
