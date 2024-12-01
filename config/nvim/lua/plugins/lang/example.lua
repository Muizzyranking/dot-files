--- example language set up using setup_lan
Utils.setup_lang({
  -- Name of the language configuration
  -- This is a required field and is often used as a default for other options
  name = "example",

  -- Filetypes associated with this language
  -- Can be a string or a table of strings
  -- If not provided, defaults to the value of 'name'
  -- this is needed for keymaps, autocmds, options and use_prettier
  ft = { "typescript", "typescriptreact", "typescript.tsx" },

  -- Add custom filetype detection
  -- This supports multiple detection methods
  add_ft = {
    -- Detect by file extension
    extension = {
      -- Map specific extensions to filetypes
      tsx = "typescriptreact",

      -- Alternative: You can add multiple mappings
      -- Alternative syntax is also possible
      ["config"] = "json",
    },

    -- Detect by filename
    filename = {
      -- Map specific filenames to filetypes
      ["tsconfig.json"] = "jsonc",
      ["package.json"] = "json",
    },

    -- Detect by pattern matching
    pattern = {
      -- Regex patterns to match file paths and assign filetypes
      [".*/components/.+%.tsx?"] = "typescriptreact",
      [".*/pages/.+%.tsx?"] = "typescriptreact",
    },

    -- Custom filetype mapping
    -- Maps one filetype to another
    filetype = {
      -- Example: map typescript to javascript for certain configurations
      typescript = "javascript",
    },
  },

  -- LSP (Language Server Protocol) Configuration
  -- Configure language servers for this filetype
  lsp = {
    -- Servers can be configured with additional options
    servers = {
      -- Each key is the server name, contains configuration
      -- check lspconfig for avaliable options and servers
      tsserver = {
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
            },
          },
        },
        -- mappings for when this server is attached
        keys = {
          {
            "lhs",
            "rhs",
            desc = "Description",
            mode = "n", -- optional, default is "n"
            -- this is for wk, i like icons for visual representation
            icon = "", -- optional, no icon by default
            -- other options that vim.keymap.set supports
          },
        },
      },
      -- Can add multiple servers
      eslint = {
        filetypes = { "typescript", "typescriptreact" },
      },
    },

    -- you can do any additional lsp server setup here
    -- return true if you don't want this server to be setup with lspconfig
    setup = {
      typescript = function()
        -- do some setup
        return true
      end,
    },
  },

  -- Formatting Configuration
  -- Configure code formatters
  -- uses conform for formatting config
  formatting = {
    -- Specify formatters for different filetypes
    formatters_by_ft = {
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
    },

    -- Custom formatters and overrides for built-in formatters
    formatters = {
      my_formatter = {
        -- This can be a string or a function that returns a string.
        -- When defining a new formatter, this is the only field that is required
        command = "my_cmd",
        -- A list of strings, or a function that returns a list of strings
        -- Return a single string instead of a list to run the command in a shell
        args = { "--stdin-from-filename", "$FILENAME" },
        inherit = true,
        -- When inherit = true, add these additional arguments to the beginning of the command.
        -- This can also be a function, like args
        prepend_args = { "--use-tabs" },
        -- When inherit = true, add these additional arguments to the end of the command.
        -- This can also be a function, like args
        append_args = { "--trailing-comma" },
      },
      -- These can also be a function that returns the formatter
      other_formatter = function(bufnr)
        return {
          command = "my_cmd",
        }
      end,
    },

    -- since lots of filetypes use prettier, this saves time by allowing pass filetypes
    -- filetypes passed will use prettier
    use_prettier = { "typescript", "typescriptreact" },
    -- Alternative: use_prettier = true  -- use for all filetypes set above

    -- Auto-format on save
    -- Can be boolean or a function
    format_on_save = true,
    -- Alternative:
    -- format_on_save = function(bufnr)
    --   return vim.api.nvim_buf_get_option(bufnr, "filetype") == "typescript"
    -- end
  },

  -- Linting Configuration
  linting = {
    -- Custom linters and overrides for built-in linters
    linters = {},
    -- Specify linters for different filetypes
    linters_by_ft = {
      typescript = { "eslint" },
      typescriptreact = { "eslint" },
    },
  },

  -- Treesitter Highlighting Configuration
  highlighting = {
    -- Specify parsers to ensure installation
    -- Can be a string or a table of strings
    parsers = { "typescript", "tsx" },

    -- Custom parser configurations
    -- Useful for custom or non-standard language parsers
    custom_parsers = {
      -- Example of a custom parser configuration
      -- tsx = {
      --   install_info = {
      --     url = "https://github.com/tree-sitter/tree-sitter-typescript",
      --     files = { "src/scanner.cc", "src/parser.c" },
      --     branch = "master"
      --   }
      -- }
    },
  },

  -- Icons Configuration (for file type icons)
  icons = {
    -- Configure custom icons for the filetype with mini icons
    default = {},
    directory = {},
    extension = {},
    file = {},
    filetype = {},
    lsp = {},
    os = {},
  },

  -- Comment String Configuration
  -- Specify how comments should be formatted for this filetype(s)
  -- Can be a string or a table
  -- if string, it will be set for filetype sepcified
  commentstring = "// %s",
  -- Alternative:
  -- commentstring = {
  --   typescript = "// %s",
  --   typescriptreact = "{/* %s */}"
  -- }

  -- Filetype-specific Keymaps
  -- Define keymaps that only work for this specific filetype
  keys = {
    {
      -- Keymap for adding a console.log
      "<leader>cl",
      "oconsole.log()<Esc>i",
      desc = "Add console.log",
      mode = "n",
    },
    {
      -- Another example keymap
      "<leader>ci",
      "oimport { } from '';<Esc>hhi",
      desc = "Add import statement",
      mode = "n",
    },
  },

  -- Filetype-specific Vim Options
  -- Set buffer-local options when this filetype is detected
  options = {
    -- Example: set specific indentation for this filetype
    shiftwidth = 2,
    tabstop = 2,
    expandtab = true,
  },

  -- Custom Plugins
  -- Add additional plugins specific to this language
  plugins = {
    -- Can be a string (plugin name) or a table with additional configuration
    "jellydn/typescript-tools.nvim",
    {
      "dmmulroy/ts-error-translator.nvim",
      ft = { "typescript", "typescriptreact" },
    },
  },
})
return {}
