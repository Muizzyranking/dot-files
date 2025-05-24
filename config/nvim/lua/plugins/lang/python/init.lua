return {
  name = "python",
  lsp = {
    inlay_hint = true,
    servers = {
      basedpyright = {
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "standard",
            },
            disableOrganizeImports = true,
          },
        },
        on_new_config = function(config, root_dir)
          local venv = require("plugins.lang.python.venv").detect_and_activate_venv(root_dir)
          if venv then
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = venv.python_path
          end
        end,
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
      basedpyright = function()
        Utils.lsp.on_attach(function(client, bufnr)
          local venv_path = vim.b[bufnr].python_venv
          local python_path = vim.b[bufnr].python_path

          if not venv_path or not python_path then
            local root = Utils.root(bufnr)
            local venv = require("plugins.lang.python.venv").detect_and_activate_venv(root)
            if venv then
              venv_path = venv.venv_path
              python_path = venv.python_path
            else
              return
            end
          end

          -- Apply Python path to client settings
          if client.settings then
            client.settings = vim.tbl_deep_extend("force", client.settings, { python = { pythonPath = python_path } })
          elseif client.config.settings then
            client.config.settings =
              vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = python_path } })
          end

          -- Force configuration update
          client.notify("workspace/didChangeConfiguration", { settings = nil })
        end, "basedpyright")
      end,
      ruff_lsp = function()
        return true
      end,
    },
  },
  formatting = {
    formatters = {
      black = {
        append_args = { "--line-length", "100" },
      },
      djlint = {
        append_args = { "--indent", "2" },
      },
    },
    formatters_by_ft = {
      python = { "black" },
      ["htmldjango"] = { "djlint" },
    },
    format_on_save = true,
  },
  linting = {
    linters = {
      flake8 = {
        args = {
          "--ignore=E501",
          "--format=%(path)s:%(row)d:%(col)d:%(code)s:%(text)s",
          "--no-show-source",
          "--stdin-display-name",
          function()
            return Utils.get_filename()
          end,
          "-",
        },
      },
    },
    linters_by_ft = {
      -- python = { "flake8" },
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
  root_patterns = {
    "manage.py",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
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
        })
        if root ~= nil then
          vim.bo[event.buf].filetype = "htmldjango"
        end
      end,
    },
    {
      pattern = "python",
      callback = function(event)
        Utils.map.create_abbrevs({
          { "true", "True" },
          { "ture", "True" },
          { "false", "False" },
          { "flase", "False" },
          { "Class", "class" },
          { "calss", "class" },
          { "none", "None" },
          { "NONE", "None" },
        }, {
          buffer = event.buf,
          builtin = "lsp_keyword",
        })
      end,
    },
    {
      pattern = "python",
      callback = function(e)
        local root = Utils.root(e.buf)
        local venv = require("plugins.lang.python.venv").detect_and_activate_venv(root)
        if venv then
          vim.b[e.buf].python_venv = venv.venv_path
          vim.b[e.buf].python_path = venv.python_path
        end
      end,
    },
    {
      event = "BufWritePost",
      pattern = { "*pyrightconfig.json" },
      callback = function()
        local basedpyright = Utils.lsp.get_clients({ name = "basedpyright" })

        if basedpyright and #basedpyright > 0 then
          vim.cmd("LspStop basedpyright")
          vim.defer_fn(function()
            vim.cmd("LspStart basedpyright")
          end, 200)
        else
          vim.cmd("LspStart basedpyright")
        end

        vim.cmd("stopinsert")
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
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
              exclude = { "venv", ".venv", ".pytest_cache" },
            },
          },
        },
      },
    },
  },
}
