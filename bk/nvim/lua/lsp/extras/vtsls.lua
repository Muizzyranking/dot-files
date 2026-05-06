return {
  enabled = false,
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
}
