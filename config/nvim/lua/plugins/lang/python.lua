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
        },
      },
    },
    setup = {
      ruff = function()
        Utils.lsp.on_attach(function(client, bufnr)
          client.server_capabilities.hoverProvider = false
          if client then
            Utils.map.set_keymap({
              "<leader>cu",
              function()
                local diag = vim.diagnostic.get(bufnr)
                local ruff_diags = vim.tbl_filter(function(d)
                  return d.source and d.source:lower() == "ruff"
                end, diag)
                if #ruff_diags > 0 then
                  Utils.lsp.action["source.fixAll.ruff"]()
                end
              end,
              desc = "Fix all fixable diagnostics",
              icon = { icon = "󰁨 ", color = "red" },
              buffer = bufnr,
            })
          end
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
  root_patterns = { "manage.py", "main.py" },
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
        })
        if root ~= nil then
          vim.bo[event.buf].filetype = "htmldjango"
        end
      end,
    },
    {
      pattern = "python",
      callback = function(event)
        Utils.map.add_to_wk()
        Utils.map.create_abbrevs({
          { "true", "True" },
          { "ture", "True" },
          { "false", "False" },
          { "flase", "False" },
        }, {
          buffer = event.buf,
          builtin = "lsp_keyword",
        })
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
      "folke/snacks.nvim",
      optional = true,
      opts = {
        picker = {
          sources = {
            files = {
              exclude = { "venv", ".venv", ".pytest_cache", ".mypy_cache", "__pycache__" },
            },
          },
        },
      },
    },
  },
}
