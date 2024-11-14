return {
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
    "neovim/nvim-lspconfig",
    opts = {
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
          Utils.lsp.on_attach(function(client, _)
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
          end, "ruff")
        end,
        ruff_lsp = function()
          return true
        end,
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = { "flake8", "djlint", "black", "djlint" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
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
      },
      formatters_by_ft = {
        -- ["python"] = { "autopep8" },
        ["python"] = { "black" },
        ["htmldjango"] = { "djlint" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "flake8" },
        htmldjango = { "djlint" },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "ninja",
        "rst",
        "htmldjango",
      },
    },
  },
}
