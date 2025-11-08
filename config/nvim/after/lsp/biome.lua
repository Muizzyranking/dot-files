return {
  workspace_required = true,
  root_markers = { "biome.json", "biome.jsonc" },
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
  on_attach = function(_, bufnr)
    vim.b[bufnr].biome_attached = true
  end,
}
