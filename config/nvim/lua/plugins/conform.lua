return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo" },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
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
  opts = function()
    local biome_supported = {
      "astro",
      "css",
      "graphql",
      "javascript",
      "javascriptreact",
      "json",
      "jsonc",
      "svelte",
      "typescript",
      "typescriptreact",
      "vue",
    }

    local biome_available = function(ctx)
      return vim.fs.root(ctx.dirname, { "biome.json", "biome.jsonc" }) ~= nil or vim.g.use_biome
    end
    local use_biome = Utils.fn.memoize(biome_available)
    local opts = {
      notify_on_error = true,
      format_on_save = false,
      default_format_opts = {
        timeout_ms = 2500,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
      formatters = {
        biome = {
          require_cwd = true,
          condition = function(_, ctx)
            return use_biome(ctx) and vim.tbl_contains(biome_supported, vim.bo[ctx.buf].filetype)
          end,
        },
        prettierd = {
          condition = function(_, ctx)
            local ft = vim.bo[ctx.buf].filetype
            return not use_biome(ctx) or not vim.tbl_contains(biome_supported, ft)
          end,
        },
        black = { append_args = { "--line-length", "85" } },
        djlint = { append_args = { "--indent", "2" } },
        ruff = require("conform.formatters.ruff_format"),
      },
      formatters_by_ft = {
        yaml = { "prettierd", "biome" },
        lua = { "stylua" },
        python = { "ruff" },
        ["htmldjango"] = { "djlint" },
        ["bash"] = { "shfmt" },
        ["sh"] = { "shfmt" },
        go = { "goimports", "gofumpt" },
        http = { "kulala-fmt" },
        ["markdown"] = { "markdownlint-cli2", "markdown-toc" },
        ["markdown.mdx"] = { "markdownlint-cli2", "markdown-toc" },
        ["json"] = { "jq" },
        ["jsonc"] = { "jq" },
      },
    }
    local use_prettier_or_biome = {
      "typescript",
      "typescriptreact",
      "javascript",
      "javascriptreact",
      "jsx",
      "tsx",
      "html",
      "css",
    }
    for _, ft in ipairs(use_prettier_or_biome) do
      opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
      table.insert(opts.formatters_by_ft[ft], "prettierd")
      if vim.list_contains(biome_supported, ft) then
        table.insert(opts.formatters_by_ft[ft], "biome")
      end
    end
    return opts
  end,
  config = function(_, opts)
    require("conform").setup(opts)
  end,
}
