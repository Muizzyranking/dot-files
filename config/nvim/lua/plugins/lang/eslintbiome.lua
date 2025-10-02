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
      biome = function(opts)
        return {
          filetypes = opts.ft,
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
        }
      end,
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
                if #eslint_diagnostics > 0 then vim.cmd("EslintFixAll") end
              end
            end,
          })
        end, "eslint")
      end,
      biome = function()
        Utils.lsp.on_attach(function(_, bufnr)
          vim.b[bufnr].biome_attached = true
        end, "biome")
        Utils.lsp.on_detach(function(_, bufnr)
          vim.b[bufnr].biome_attached = false
        end, "biome")
      end,
    },
  },
}
