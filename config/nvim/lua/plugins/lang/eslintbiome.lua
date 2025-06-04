return {
  name = "eslintbiome",
  ft = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "json",
    "vue",
    "svelte",
    "markdown",
    "html",
    "mjs",
    "cjs",
  },
  lsp = {
    servers = {
      eslint = {
        settings = {
          workingDirectories = { mode = "auto" },
        },
      },
      biome = {
        root_dir = function(fname)
          local root_files = { "biome.json", "biome.jsonc" }
          root_files = require("lspconfig.util").insert_package_json(root_files, "biome", fname)
          return vim.fs.dirname(vim.fs.find(root_files, { path = fname, upward = true })[1])
        end,
      },
    },
    setup = {
      eslint = function()
        Utils.lsp.on_attach(function(_, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              local cl = Utils.lsp.get_clients({ name = "eslint", bufnr = bufnr })[1]
              if cl then
                local diagnostics = vim.diagnostic.get(bufnr)
                local eslint_diagnostics = vim.tbl_filter(function(d)
                  return d.source and d.source:lower() == "eslint"
                end, diagnostics)
                if #eslint_diagnostics > 0 then
                  vim.cmd("EslintFixAll")
                end
              end
            end,
          })
        end, "eslint")
      end,
    },
  },
}
