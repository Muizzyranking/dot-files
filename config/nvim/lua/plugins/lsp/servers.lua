local utils = require("utils.lsp")
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
        utils.action["source.organizeImports"],
        { desc = "Organize Imports" },
      },
    },
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
    keys = {
      {
        "gD",
        function()
          local params = vim.lsp.util.make_position_params()
          utils.execute({
            command = "typescript.goToSourceDefinition",
            arguments = { params.textDocument.uri, params.position },
            open = true,
          })
        end,
        { desc = "Goto Source Definition" },
      },
      {
        "gR",
        function()
          utils.execute({
            command = "typescript.findAllFileReferences",
            arguments = { vim.uri_from_bufnr(0) },
            open = true,
          })
        end,
        { desc = "File References" },
      },
      {
        "<leader>co",
        utils.action["source.organizeImports"],
        { desc = "Organize Imports" },
      },
      {
        "<leader>cM",
        utils.action["source.addMissingImports.ts"],
        { desc = "Add missing imports" },
      },
      {
        "<leader>cu",
        utils.action["source.removeUnused.ts"],
        { desc = "Remove unused imports" },
      },
      {
        "<leader>cD",
        utils.action["source.fixAll.ts"],
        { desc = "Fix all diagnostics" },
      },
      {
        "<leader>cV",
        function()
          utils.execute({ command = "typescript.selectTypeScriptVersion" })
        end,
        { desc = "Select TS workspace version" },
      },
    },
  },

  jsonls = {
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
          setType = false,
          paramType = true,
          paramName = "Disable",
          semicolon = "Disable",
          arrayIndex = "Disable",
        },
        codeLens = {
          enable = true,
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
