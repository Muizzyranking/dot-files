local utils = require("utils")
local M = {}

M.lsp = {
  clangd = {
    root_dir = function(fname)
      return require("lspconfig.util").root_pattern(
        "Makefile",
        "configure.ac",
        "configure.in",
        "config.h.in",
        "meson.build",
        "meson_options.txt",
        "build.ninja"
      )(fname) or require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt")(fname) or require(
        "lspconfig.util"
      ).find_git_ancestor(fname)
    end,
    capabilities = {
      offsetEncoding = { "utf-16" },
    },
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders",
      "--fallback-style=llvm",
      "--offset-encoding=utf-16",
    },
    init_options = {
      usePlaceholders = true,
      completeUnimported = true,
      clangdFileStatus = true,
    },
  },

  basedpyright = {
    settings = {
      basedpyright = {
        analysis = {
          -- Ignore all files for analysis to exclusively use Ruff for linting
          -- ignore = { "*" },
          typeCheckingMode = "off",
        },
        -- Using Ruff's import organizer
        disableOrganizeImports = true,
      },
      -- python = {
      --   analysis = {
      --     -- Ignore all files for analysis to exclusively use Ruff for linting
      --     ignore = { "*" },
      --   },
      -- },
    },
  },
  ruff_lsp = {
    on_attach = function(client, bufnr)
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end
      if client.name == "ruff_lsp" then
        client.server_capabilities.hoverProvider = false

        map("n", "<leader>co", function()
          vim.lsp.buf.code_action({
            apply = true,
            context = {
              only = { "source.organizeImports" },
              diagnostics = {},
            },
          })
        end, "Organize Imports")
      end
    end,
  },
  marksman = {},
  emmet_ls = {},
  cssls = {},
  html = {
    filetypes = { "html", "htmldjango" },
  },
  sqlls = {},
  bashls = {
    filetypes = { "sh", "bash" },
  },
  eslint = {
    settings = {
      workingDirectories = { mode = "auto" },
    },
  },
  vtsls = {
    settings = {
      complete_function_calls = true,
      vtsls = {
        enableMoveToFileCodeAction = true,
      },
      typescript = {
        updateImportsOnFileMove = { enabled = "always" },
        experimental = {
          completion = {
            enableServerSideFuzzyMatch = true,
          },
        },
        suggest = {
          completeFunctionCalls = true,
        },
        inlayHints = {
          enumMemberValues = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          variableTypes = { enabled = false },
        },
      },
    },
    on_attach = function(client, bufnr)
      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
      end
      if client.name == "vtsls" then
        if utils.has("nvim-vtsls") then
          map("gD", function()
            require("vtsls").commands.goto_source_definition(0)
          end, "Goto Source Definition")
          map("gR", function()
            require("vtsls").commands.file_references(0)
          end, "Goto File Definition")
          map("<leader>co", function()
            require("vtsls").commands.organize_imports(0)
          end, "Organize imports")
          map("<leader>cM", function()
            require("vtsls").commands.add_missing_imports(0)
          end, "Add missing imports")
          map("<leader>cD", function()
            require("vtsls").commands.fix_all(0)
          end, "Fix all diagnostics")
        end
      end
    end,
  },

  jsonls = {
    -- lazy-load schemastore when needed
    on_new_config = function(new_config)
      new_config.settings.json.schemas = new_config.settings.json.schemas or {}
      vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
    end,
    settings = {
      json = {
        format = {
          enable = true,
        },
        validate = { enable = true },
      },
    },
  },

  lua_ls = {
    settings = {
      Lua = {
        cmd = { "lua-language-server" },
        hint = {
          enable = true,
          arrayIndex = "Disable",
        },
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = {
            "${3rd}/luv/library",
            unpack(vim.api.nvim_get_runtime_file("", true)),
          },
        },
        completion = {
          callSnippet = "Replace",
        },
      },
    },
  },
}

M.fts_n_linters = {
  "stylua",
  "autopep8",
  "prettier",
  "prettierd",
  "sql-formatter",
  "flake8",
  "shellcheck",
  "shfmt",
  "jsonlint",
  "eslint_d",
  "djlint",
  -- "markdownlint",
}

return M
