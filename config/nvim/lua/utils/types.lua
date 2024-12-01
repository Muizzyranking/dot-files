---@class AddFt
---@field extension? table<string, string> # Map specific extensions to filetypes
---@field filename? table<string, string> # Map specific filenames to filetypes
---@field pattern? table<string, string> # Regex patterns to match file paths and assign filetypes
---@field filetype? table<string, string> # Custom filetype mapping

---@class AutocmdConfig
---@field events? string|string[] # The event(s) to trigger on
---@field pattern? string|string[] # The pattern(s) to match
---@field command? string # The command to run
---@field callback? fun(args: table) # The callback function to run

---@class LspConfig
---@field servers lspconfig.options # Server configurations
---@field setup? table<string, fun(server:string, opts:_.lspconfig.options):boolean?> # Setup functions
---@field custom_servers? table # Additional LSP options

---@class FormattingConfig
---@field formatters? table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride> Custom formatters and overrides for built-in formatters.
---@field formatters_by_ft? table<string, conform.FiletypeFormatter> Map of filetype to formatters
---@field format_on_save? boolean # Whether to format on save
---@field use_prettier? boolean|string[] # Whether to use prettier for this filetypes or use prettier for specific filetypes

---@class LintingConfig
---@field linters_by_ft? table<string, string[]> # Linters by filetype
---@field linters? table<string, lint.Linter|fun():lint.Linter># linters

---@class TreesitterConfig
---@field parsers? string[] # Parser names to install
---@field custom_parsers? ParserInfo # Custom parser configurations

---@class LanguageConfig
---@field name string # Language name
---@field ft? string|string[] # Filetype(s)
---@field add_ft? AddFt # Filetype detection configuration
---@field autocmds? AutocmdConfig[] # Autocommands
---@field lsp? LspConfig # LSP configuration
---@field formatting? FormattingConfig # Formatting configuration
---@field linting? LintingConfig # Linting configuration
---@field highlighting? TreesitterConfig # Treesitter configuration
---@field plugins? table[] # Additional plugins
---@field keys? table # Keymaps
---@field options? table<string, any> # Buffer options
---@field icons? table<string, table> # File icons configuration
---@field commentstring? string|table<string, any> # Comment string configuration
