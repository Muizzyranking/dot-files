return {
  name = "clarity",
  ft = "clarity",
  commentstring = ";; %s",
  add_ft = {
    extension = { clar = "clarity" },
  },
  lsp = {
    servers = {
      clarity = {
        cmd = { "clarinet", "lsp" },
        filetypes = { "clar", "clarity" },
        single_file_support = true,
        init_options = {},
        root_dir = function(fname)
          return require("lspconfig").util.root_pattern(".git", "Clarinet.toml")(fname)
        end,
      },
    },
  },
  highlighting = {
    custom_parsers = {
      clarity = {
        install_info = {
          url = "https://github.com/xlittlerag/tree-sitter-clarity.git",
          files = { "src/parser.c" },
          branch = "main",
          generate_requires_npm = false,
          requires_generate_from_grammar = false,
        },
        filetype = { "clarity", "clar" },
      },
    },
  },
  icons = {
    extension = {
      ["clar"] = { glyph = "", hl = "MiniIconsYellow" },
    },
  },
  autocmds = {
    {
      events = { "BufRead", "BufNewFile" },
      pattern = "*.clar",
      command = "set filetype=clarity",
    },
    -- {
    --   events = { "BufWritePost" },
    --   command = "e %",
    -- },
  },
}
