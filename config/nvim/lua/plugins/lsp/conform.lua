local M = {}

M.root_file = function(files)
  return function(_, ctx)
    return vim.fs.root(ctx.dirname, files)
  end
end

local use_biome = function(ctx)
  if M.root_file({ "biome.json", "biome.jsonc" })(nil, ctx) then
    return true
  end
  if vim.g.use_biome then
    return true
  end
  return false
end

M.use_biome = Utils.memoize(use_biome)

M.biome_supported = {
  "astro",
  "css",
  "graphql",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  -- "markdown",
  "svelte",
  "typescript",
  "typescriptreact",
  "vue",
  -- "yaml",
}

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
        end,
        mode = { "n", "v" },
        desc = "Format Injected Langs",
      },
    },
    opts_extend = { "use_prettier_biome" },
    opts = {
      -- since prettier is used for multiple filetypes
      -- this options allows to specify which filetypes to use with prettier
      use_prettier_biome = { "yaml" },
      notify_on_error = true,
      default_format_opts = {
        timeout_ms = 2500,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
      formatters = {},
      formatters_by_ft = {},
    },
  },
  {
    "stevearc/conform.nvim",
    config = function(_, opts)
      opts.use_prettier_biome = opts.use_prettier_biome or {}
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters = opts.formatters or {}
      opts.formatters["biome"] = {
        require_cwd = true,
        condition = function(_, ctx)
          local ft = vim.bo[ctx.buf].filetype
          return M.use_biome(ctx) and vim.tbl_contains(M.biome_supported, ft)
        end,
      }
      opts.formatters["prettierd"] = {
        condition = function(_, ctx)
          local ft = vim.bo[ctx.buf].filetype
          return not M.use_biome(ctx) or not vim.tbl_contains(M.biome_supported, ft)
        end,
      }

      for _, ft in ipairs(opts.use_prettier_biome) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "prettierd")
        if vim.list_contains(M.biome_supported, ft) then
          table.insert(opts.formatters_by_ft[ft], "biome")
        end
      end
      require("conform").setup(opts)
    end,
  },
}
