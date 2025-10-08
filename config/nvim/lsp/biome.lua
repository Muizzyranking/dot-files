Utils.lsp.register_keys("biome", {
  {
    "<leader>co",
    Utils.lsp.action["source.organizeImports.biome"],
    desc = "Organize Imports",
    icon = { icon = "󰺲" },
  },
})

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
  },
  on_attach = function(_, bufnr)
    vim.b[bufnr].biome_attached = true
  end,
}
