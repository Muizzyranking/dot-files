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
      basedpyright = function()
        Utils.lsp.on_attach(function(client, bufnr)
          if os.getenv("VIRTUAL_ENV") then
            return
          end

          local root = Utils.root(bufnr)
          if not root then
            return
          end
          local venv_names = { "venv", ".venv", "env", ".env" }

          for _, venv in ipairs(venv_names) do
            local venv_path = root .. "/" .. venv
            local activate_path = venv_path .. "/bin/activate"
            local python_path = venv_path .. "/bin/python"

            if vim.fn.filereadable(activate_path) == 1 and vim.fn.isdirectory(venv_path) == 1 then
              -- Set environment variables
              vim.env.VIRTUAL_ENV = venv_path
              if not vim.env.PATH:find(venv_path .. "/bin", 1, true) then
                vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH
              end
              vim.g.python3_host_prog = python_path
              vim.b.python_venv = venv_path

              if client.settings then
                client.settings =
                  vim.tbl_deep_extend("force", client.settings, { python = { pythonPath = python_path } })
              elseif client.config.settings then
                client.config.settings =
                  vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = python_path } })
              end

              client.notify("workspace/didChangeConfiguration", { settings = nil })
              break
            end
          end
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
        append_args = {
          "--indent",
          "2",
        },
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
            return vim.api.nvim_buf_get_name(0)
          end,
          "-",
        },
      },
    },
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
              exclude = { "venv", ".venv", ".pytest_cache", ".mypy_cache", "__pycache__" },
            },
          },
        },
      },
    },
  },
}
