return Utils.setup_lang({
  name = "json",
  ft = { "json", "json5", "jsonc" },
  lsp = {
    servers = {
      jsonls = {
        on_new_config = function(new_config)
          new_config.settings.json.schemas = new_config.settings.json.schemas or {}
          vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
        end,
        settings = {
          json = {
            format = {
              enable = true,
            },
            validate = { enable = true },
          },
        },
      },
    },
  },
  formatting = {
    formatters_by_ft = {
      ["json"] = { "jq" },
      ["jsonc"] = { "jq" },
    },
    format_on_save = true,
  },
  highlighting = {
    parsers = { "json", "json5", "jsonc" },
  },
  keys = {
    {
      "o",
      function()
        local line = vim.api.nvim_get_current_line()

        local should_add_comma = string.find(line, "[^,{[]$")
        if should_add_comma then
          return "A,<cr>"
        else
          return "o"
        end
      end,
      expr = true,
    },
  },
  options = {
    shiftwidth = 2,
    tabstop = 2,
  },
  plugins = {
    {
      "b0o/SchemaStore.nvim",
      lazy = true,
      version = false, -- last release is way too old
    },
  },
})
