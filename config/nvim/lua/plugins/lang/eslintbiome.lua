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
          cmd = function(dispatchers, config)
            config = config or {}
            local cmd = "biome"
            local local_cmd = config.root_dir and config.root_dir .. "/node_modules/.bin/biome"
            if local_cmd and Utils.is_executable(local_cmd) then cmd = local_cmd end
            return vim.lsp.rpc.start({ cmd, "lsp-proxy" }, dispatchers)
          end,
          filetypes = opts.ft,
          workspace_required = true,
          root_dir = function(buf, on_dir)
            local root_markers = { "package.json", "pacakge-lock.json", "pnpm-lock.json" }
            root_markers = { root_markers, { ".git" } }
            local project_root = vim.fs.root(buf, root_markers) or vim.fn.getcwd()

            local filename = Utils.get_filename(buf)

            local biome_config_files = { "biome.json", "biome.jsonc" }
            biome_config_files =
              Utils.root.markers_with_field(biome_config_files, { "package.json", "package.json5" }, "biome", filename)

            local using_biome = vim.fs.find(biome_config_files, {
              path = filename,
              upward = true,
              type = "file",
              limit = 1,
              stop = vim.fs.dirname(project_root),
            })[1]
            if not using_biome then return end
            on_dir(project_root)
          end,
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
        Utils.lsp.on_dettach(function(_, bufnr)
          vim.b[bufnr].biome_attached = false
        end, "biome")
      end,
    },
  },
}
