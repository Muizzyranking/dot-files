return {
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
      ["neotest-python"] = {
        -- Here you can specify the settings for the adapter, i.e.
        runner = "pytest",
        python = ".venv/bin/python",
      },
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
  autocmds = {
    {
      pattern = "html",
      group = "htmldjango detection",
      callback = function(event)
        local buf = event.buf
        local root = Utils.root.find_pattern_root(buf, {
          "manage.py",
          "urls.py",
          "settings.py",
          "templates/",
          "apps.py",
        })
        if root ~= nil then
          vim.api.nvim_buf_set_option(event.buf, "filetype", "htmldjango")
        end
      end,
    },
    {
      pattern = "python",
      callback = function(event)
        local buf = event.buf
        local opts = { buffer = buf }
        Utils.create_abbrev("true", "True", opts)
        Utils.create_abbrev("false", "False", opts)
      end,
    },
  },
  keys = {
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
}
