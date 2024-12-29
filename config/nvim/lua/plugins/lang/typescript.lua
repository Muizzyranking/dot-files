return Utils.setup_lang({
  name = "typescript",
  ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  lsp = {
    servers = {
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
        keys = {
          {
            "<leader>D",
            function()
              local params = vim.lsp.util.make_position_params()
              Utils.lsp.execute({
                command = "typescript.goToSourceDefinition",
                arguments = { params.textDocument.uri, params.position },
                open = true,
              })
            end,
            desc = "Goto Source Definition",
          },
          {
            "gR",
            function()
              Utils.lsp.execute({
                command = "typescript.findAllFileReferences",
                arguments = { vim.uri_from_bufnr(0) },
                open = true,
              })
            end,
            desc = "File References",
          },
          {
            "<leader>co",
            Utils.lsp.action["source.organizeImports"],
            desc = "Organize Imports",
          },
          {
            "<leader>cM",
            Utils.lsp.action["source.addMissingImports.ts"],
            desc = "Add missing imports",
          },
          {
            "<leader>cu",
            Utils.lsp.action["source.removeUnused.ts"],
            desc = "Remove unused imports",
          },
          {
            "<leader>cD",
            Utils.lsp.action["source.fixAll.ts"],
            desc = "Fix all diagnostics",
          },
          {
            "<leader>cV",
            function()
              Utils.lsp.execute({
                command = "typescript.selectTypeScriptVersion",
              })
            end,
            desc = "Select TS workspace version",
          },
        },
      },
    },
    setup = {
      tsserver = function()
        return true
      end,
      ts_ls = function()
        return true
      end,
      vtsls = function()
        Utils.lsp.on_attach(function(client, _)
          client.commands["_typescript.moveToFileRefactoring"] = function(command, _)
            ---@type string, string, lsp.Range
            local action, uri, range = unpack(command.arguments)

            local function move(newf)
              client.request("workspace/executeCommand", {
                command = command.command,
                arguments = { action, uri, range, newf },
              })
            end

            local fname = vim.uri_to_fname(uri)
            client.request("workspace/executeCommand", {
              command = "typescript.tsserverRequest",
              arguments = {
                "getMoveToRefactoringFileSuggestions",
                {
                  file = fname,
                  startLine = range.start.line + 1,
                  startOffset = range.start.character + 1,
                  endLine = range["end"].line + 1,
                  endOffset = range["end"].character + 1,
                },
              },
            }, function(_, result)
              ---@type string[]
              local files = result.body.files
              table.insert(files, 1, "Enter new path...")
              vim.ui.select(files, {
                prompt = "Select move destination:",
                format_item = function(f)
                  return vim.fn.fnamemodify(f, ":~:.")
                end,
              }, function(f)
                if f and f:find("^Enter new path") then
                  vim.ui.input({
                    prompt = "Enter move destination:",
                    default = vim.fn.fnamemodify(fname, ":h") .. "/",
                    completion = "file",
                  }, function(newf)
                    ---@diagnostic disable-next-line: redundant-return-value
                    return newf and move(newf)
                  end)
                elseif f then
                  move(f)
                end
              end)
            end)
          end
        end, "vtsls")
      end,
    },
  },

  formatting = {
    -- sets pretter for all filetype
    use_prettier_biome = true,
    format_on_save = true,
  },

  highlighting = {
    parsers = {
      "typescript",
      "javascript",
      "tsx",
    },
  },
  icons = {
    file = {
      [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
      [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
      [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
      [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
      ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
      ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
      ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
      ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
      ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
    },
  },
  keys = {
    {
      "t",
      function()
        vim.api.nvim_feedkeys("t", "n", true) -- pass through the trigger char
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local textBeforeCursor = vim.api.nvim_get_current_line():sub(col - 3, col)
        if textBeforeCursor ~= "awai" then
          return
        end
        -----------------------------------------------------------------------------

        local funcNode
        local functionNodes = { "arrow_function", "function_declaration", "function" }
        repeat -- loop trough ancestors till function node found
          funcNode = vim.treesitter.get_node()
          funcNode = funcNode and funcNode:parent()
          if not funcNode then
            return
          end
        until vim.tbl_contains(functionNodes, funcNode:type())
        local functionText = vim.treesitter.get_node_text(funcNode, 0)

        if vim.startswith(functionText, "async") then
          return
        end -- already async

        local startRow, startCol = funcNode:start()
        vim.api.nvim_buf_set_text(0, startRow, startCol, startRow, startCol, { "async " })
      end,
      mode = "i",
      desc = "Auto add async",
    },
  },
  options = {
    shiftwidth = 2,
    tabstop = 2,
  },
  plugins = {
    {
      "garymjr/nvim-snippets",
      optional = true,
      opts = {
        extended_filetypes = {
          { javascript = { "javascriptreact" } },
          { typescript = { "javascript" } },
        },
      },
    },
    { import = "plugins.lang.eslintbiome" },
  },
})
