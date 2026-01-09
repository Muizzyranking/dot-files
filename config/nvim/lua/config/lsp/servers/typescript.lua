return {
  biome = {
    keys = {
      {
        "<leader>co",
        Utils.lsp.action["source.organizeImports.biome"],
        desc = "Organize Imports",
        icon = { icon = "󰺲" },
      },
      {
        "<leader>cb",
        Utils.lsp.action["source.fixAll.biome"],
        desc = "Fix all diagnostics (biome)",
        icon = { icon = "󰁨" },
      },
    },
  },
  eslint = {
    keys = {
      {
        "<leader>cu",
        "<cmd>LspEslintFixAll<cr>",
        desc = "Fix all (eslint)",
        icon = { icon = "󰁨 ", color = "red" },
      },
    },
  },
  tsgo = {
    enabled = false,
    keys = {
      {
        "<leader>ci",
        function()
          vim.lsp.buf.code_action({
            filter = function(a)
              return a.title:match("Add import from") or a.kind == "quickfix"
            end,
            apply = true,
          })
        end,
        desc = "Add missing imports",
      },
    },
  },
  vtsls = {
    enabled = true,
    keys = {
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
      { "<leader>ci", Utils.lsp.action["source.addMissingImports.ts"], desc = "Add missing imports" },
      { "<leader>cu", Utils.lsp.action["source.removeUnused.ts"], desc = "Remove unused imports" },
      { "<leader>cD", Utils.lsp.action["source.fixAll.ts"], desc = "Fix all diagnostics" },
      {
        "<leader>cV",
        function()
          Utils.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
        end,
        desc = "Select TS workspace version",
      },
    },
  },
}
