return {
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
}
