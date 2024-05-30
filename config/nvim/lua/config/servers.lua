local M = {}
local inlay_hints_settings = {
  includeInlayEnumMemberValueHints = true,
  includeInlayFunctionLikeReturnTypeHints = true,
  includeInlayFunctionParameterTypeHints = true,
  includeInlayParameterNameHints = "literal",
  includeInlayParameterNameHintsWhenArgumentMatchesName = false,
  includeInlayPropertyDeclarationTypeHints = true,
  includeInlayVariableTypeHints = false,
  includeInlayVariableTypeHintsWhenTypeMatchesName = false,
}

M.lsp = {
  -- lsp config here to mak things less cluttered
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
      pyright = {
        -- Using Ruff's import organizer
        disableOrganizeImports = true,
      },
      python = {
        analysis = {
          -- Ignore all files for analysis to exclusively use Ruff for linting
          ignore = { "*" },
        },
      },
    },
  },
  ruff_lsp = {},
  marksman = {},
  emmet_ls = {},
  cssls = {},
  html = {},
  sqlls = {},
  bashls = {
    filetypes = { "sh", "bash" },
  },
  eslint = {
    settings = {
      workingDirectories = { mode = "auto" },
    },
  },

  -- tsserver = {
  --   ---@diagnostic disable-next-line: missing-fields
  --   -- root_dir = function(...)
  --   --   return require("lspconfig.util").root_pattern(".git")(...)
  --   -- end,
  --   root_dir = function(...)
  --     local util = require("lspconfig.util")
  --     local root_pattern = util.root_pattern(".git", "package.json", "tsconfig.json", "jsconfig.json")
  --     local root_dir = root_pattern(...) or util.path.dirname(...)
  --     return root_dir
  --   end,
  --   single_file_support = false,
  --   settings = {
  --     typescript = {
  --       inlayHints = inlay_hints_settings,
  --     },
  --     javascript = {
  --       inlayHints = inlay_hints_settings,
  --     },
  --     completions = {
  --       completeFunctionCalls = true,
  --     },
  --   },
  -- },
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
      javascript = {
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

M.on_attach = function(client, bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- Keymaps for ruff
  if client.name == "ruff_lsp" or "ruff" then
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

  -- Keymaps for vtsls
  if client.name == "vtsls" then
    local ts_js_keys = {
      {
        mode = "n",
        keys = "gD",
        command = function()
          require("vtsls").commands.goto_source_definition(0)
        end,
        desc = "Goto Source Definition",
      },
      {
        mode = "n",
        keys = "gR",
        command = function()
          require("vtsls").commands.file_references(0)
        end,
        desc = "Goto File Definition",
      },
      {
        mode = "n",
        keys = "<leader>co",
        command = function()
          require("vtsls").commands.organize_imports(0)
        end,
        desc = "Organize imports",
      },
      {
        mode = "n",
        keys = "<leader>cM",
        command = function()
          require("vtsls").commands.add_missing_imports(0)
        end,
        desc = "Add missing imports",
      },
      {
        mode = "n",
        keys = "<leader>cD",
        command = function()
          require("vtsls").commands.fix_all(0)
        end,
        desc = "Fix all diagnostics",
      },
    }

    for _, keymap in ipairs(ts_js_keys) do
      map(keymap.mode, keymap.keys, keymap.command, keymap.desc)
    end
  end
  -- on attach for clangd
  if client.name == "clangd" then
    vim.keymap.set("n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", { desc = "Switch Source/Header (C/C++)" })
  end
end

M.fts_n_linters = {
  "stylua", -- Used to format lua code
  "autopep8",
  "prettier",
  "prettierd",
  "sql-formatter",
  "flake8",
  "shellcheck",
  "shfmt",
  "jsonlint",
  "eslint_d",
  -- "markdownlint",
}

return M
