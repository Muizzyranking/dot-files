---@diagnostic disable: param-type-mismatch
return {
  name = "typescript",
  ft = { "typescript", "typescriptreact", "javascript", "javascriptreact", "jsx", "tsx" },
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
      "<leader>cc",
      function()
        Utils.color_converter()
      end,
      desc = "Convert color",
      icon = { icon = "󰸌 ", color = "green" },
      mode = { "n", "v" },
    },
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
        local safety_counter = 0
        local max_iterations = 100 -- Prevent infinite loops

        -- Get initial node
        local current_node = vim.treesitter.get_node()
        if not current_node then
          print("No treesitter node found at cursor")
          return
        end

        repeat
          safety_counter = safety_counter + 1
          funcNode = current_node
          current_node = current_node:parent()

          -- Safety checks
          if safety_counter >= max_iterations then
            print("Exceeded maximum number of parent node checks")
            return
          end

          if not current_node then
            print("Reached root without finding function node")
            return
          end

          funcNode = current_node
        until vim.tbl_contains(functionNodes, funcNode:type())

        -- Additional validation before modification
        if not funcNode or not funcNode:type() then
          print("Invalid function node")
          return
        end

        local functionText = vim.treesitter.get_node_text(funcNode, 0)
        if not functionText then
          print("Could not get function text")
          return
        end

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
      "folke/snacks.nvim",
      optional = true,
      opts = {
        picker = {
          sources = {
            files = {
              exclude = { "node_modules" },
            },
          },
        },
      },
    },
  },
}
