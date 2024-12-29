return Utils.setup_lang({
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
      biome = {},
    },
    setup = {
      eslint = function()
        Utils.lsp.on_attach(function(_, bufnr)
          vim.api.nvim_create_autocmd("BufWritePost", {
            buffer = bufnr,
            callback = function()
              local cl = Utils.lsp.get_clients({ name = "eslint", bufnr = bufnr })[1]
              if cl then
                local diag = vim.diagnostic.get(bufnr, { namespace = vim.lsp.diagnostic.get_namespace(cl.id) })
                if #diag > 0 then
                  vim.cmd("EslintFixAll")
                end
              end
            end,
          })
        end, "eslint")
      end,
    },
  },
})
