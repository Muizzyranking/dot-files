return {
  name = "php",
  ft = "php",
  root = { "composer.json", ".phpactor.json", ".phpactor.yml" },
  highlighting = { parsers = { "php", "phpdoc" } },
  lsp = {
    servers = {
      -- phpactor = {},
      intelephense = {},
    },
  },
  formatting = {
    formatters_by_ft = {
      php = { "php_cs_fixer" },
    },
  },
  linting = {
    linters_by_ft = {
      php = { "phpcs" },
      -- php = { "pint", "phpcs" },
    },
  },
}
