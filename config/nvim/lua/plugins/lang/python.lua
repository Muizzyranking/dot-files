return Utils.setup_lang({
  name = "python",
  lsp = {
    servers = {
      basedpyright = {
        settings = {
          basedpyright = {
            analysis = {
              -- Ignore all files for analysis to exclusively use Ruff for linting
              -- ignore = { "*" },
              typeCheckingMode = "standard",
            },
            -- Using Ruff's import organizer
            disableOrganizeImports = true,
          },
        },
      },
      ruff = {
        keys = {
          {
            "<leader>co",
            Utils.lsp.action["source.organizeImports"],
            desc = "Organize Imports",
          },
          {
            "<leader>cu",
            Utils.lsp.action["source.fixAll"],
            desc = "Fix all fixable diagnostics",
          },
        },
      },
    },
    setup = {
      ruff = function()
        Utils.lsp.on_attach(function(client, _)
          client.server_capabilities.hoverProvider = false
        end, "ruff")
      end,
      ruff_lsp = function()
        return true
      end,
    },
  },
  formatting = {
    formatters = {
      djlint = {
        command = "djlint",
        args = function()
          return {
            "--reformat",
            "-",
            "--indent",
            "2",
          }
        end,
      },
      black = {
        append_args = { "--line-length", "79" },
      },
    },
    formatters_by_ft = {
      python = { "black" },
      ["htmldjango"] = { "djlint" },
    },
    format_on_save = true,
  },
  linting = {
    linters_by_ft = {
      python = { "flake8" },
      htmldjango = { "djlint" },
    },
  },
  test = {
    dependencies = { "nvim-neotest/neotest-python" },
    adapters = {
      ["python"] = {},
    },
  },
  highlighting = {
    parsers = {
      "python",
      "ninja",
      "rst",
      "htmldjango",
    },
  },
  keys = {
    {
      "<F5>",
      function()
        Utils.runner.setup("python")
      end,
      icon = { icon = " ", color = "red" },
      desc = "Code runner",
      mode = "n",
    },
    {
      "<leader>cb",
      [[<Cmd>normal! ggO#!/usr/bin/env python3<CR><Esc>]],
      icon = { icon = " ", color = "red" },
      desc = "Add shebang (env)",
      silent = true,
    },
    {
      "<leader>cB",
      [[<Cmd>normal! ggO#!/usr/bin/python3<CR><Esc>]],
      icon = { icon = " ", color = "red" },
      desc = "Add shebang",
      silent = true,
    },
  },

  plugins = {
    {
      "linux-cultist/venv-selector.nvim",
      cmd = "VenvSelect",
      keys = { { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv", ft = "python" } },
      opts = {
        dap_enabled = false,
        name = {
          "venv",
          ".venv",
          "env",
          ".env",
        },
      },
    },
    {
      "nvim-telescope/telescope.nvim",
      optional = true,
      opts = {
        defaults = {
          file_ignore_patterns = {
            "venv",
            "env",
          },
        },
      },
    },
  },
})
