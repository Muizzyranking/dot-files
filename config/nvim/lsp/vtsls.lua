local settings = {
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
}
return {
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
    },
    typescript = settings,
    javascript = settings,
  },
  on_attach = function(client, _)
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
  end,
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
    -- {
    --   "<leader>co",
    --   Utils.lsp.action["source.organizeImports"],
    --   desc = "Organize Imports",
    --   cond = function()
    --     local buf = Utils.ensure_buf(0)
    --     return not vim.b[buf].biome_attached
    --   end,
    --   icon = { icon = "󰺲" },
    -- },
    {
      "<leader>ci",
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
}
