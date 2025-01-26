---@class setup_lang.add_ft
---@field extension? table<string, string> # Map specific extensions to filetypes
---@field filename? table<string, string> # Map specific filenames to filetypes
---@field pattern? table<string, string> # Regex patterns to match file paths and assign filetypes
---@field filetype? table<string, string> # Custom filetype mapping

---@class setup_lang.autocmd
---@field events? string|string[] # The event(s) to trigger on
---@field pattern? string|string[] # The pattern(s) to match
---@field command? string # The command to run
---@field callback? fun(args: table) # The callback function to run

---@class setup_lang.lspconfig
---@field servers lspconfig.options # Server configurations
---@field setup? table<string, fun(server:string, opts:_.lspconfig.options):boolean?> # Setup functions
---@field custom_servers? table # Additional LSP options

---@class setup_lang.formatting
---@field formatters? table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride> Custom formatters and overrides for built-in formatters.
---@field formatters_by_ft? table<string, conform.FiletypeFormatter> Map of filetype to formatters
---@field format_on_save? boolean # Whether to format on save
---@field use_prettier_biome? boolean|string[] # Whether to use prettier for this filetypes or use prettier for specific filetypes

---@class setup_lang.linting
---@field linters_by_ft? table<string, string[]> # Linters by filetype
---@field linters? table<string, lint.Linter|fun():lint.Linter># linters

---@class setup_lang.treesitter
---@field parsers? string[] # Parser names to install
---@field custom_parsers? ParserInfo # Custom parser configurations

---@class setup_lang.treesitter
---@field adapters? table<string, fun():table> # Adapters for tests
---@field dependencies? string[] # Dependencies for tests

---@class setup_lang.config
---@field name string # Language name
---@field ft? string|string[] # Filetype(s)
---@field add_ft? setup_lang.add_ft # Filetype detection configuration
---@field autocmds? setup_lang.autocmd[] # Autocommands
---@field lsp? setup_lang.lspconfig # LSP configuration
---@field tools? string[]|fun() # Tools to be installed
---@field test? setup_lang.treesitter # adapters for tests
---@field formatting? setup_lang.formatting # Formatting configuration
---@field linting? setup_lang.linting # Linting configuration
---@field highlighting? setup_lang.treesitter # Treesitter configuration
---@field plugins? table[] # Additional plugins
---@field keys? table # Keymaps
---@field options? table<string, any> # Buffer options
---@field icons? table<string, table> # File icons configuration
---@field commentstring? string|table<string, any> # Comment string configuration

---@class utils.maptable
---@field [1] string
---@field [2] string|function
---@field desc? string|function
---@field mode? string|string[]
---@field buffer? number|boolean
---@field icon? string|function
---@field silent? boolean
---@field remap? boolean
---@field expr? boolean

---@class utils.togglemap
---@field [1] string The keymap to be set.
---@field name? string The name of the toggle option (used in notifications and descriptions).
---@field desc? string|fun(state: boolean):string A description or a function returning a description based on the toggle state.
---@field icon? table Icons for the enabled and disabled states.
---@field icon.enabled? string Icon for the enabled state (default: "").
---@field icon.disabled? string Icon for the disabled state (default: "").
---@field color.enabled? string Color for the enabled state icon (default: "green").
---@field color.disabled? string Color for the disabled state icon (default: "yellow").
---@field get_state fun():boolean A function returning the current state of the toggle (true for enabled, false for disabled).
---@field change_state fun(state: boolean) A function to change the state of the toggle.
---@field toggle_fn? fun() A custom function to execute when toggling the state. If not provided, a default implementation is used.
---@field notify? boolean Whether to display notifications when toggling (default: true).
---@field set_key? boolean Whether to set the keymap directly (default: true). If false, the function returns the mapping table instead.

---@class color_converter.color_pattern
---@field pattern string The strict validation pattern
---@field regex string The buffer matching regex

---@class color_converter.parsers
---@field hex function Hex color parser
---@field rgb function RGB color parser
---@field rgba function RGBA color parser
---@field hsl function HSL color parser
---@field hsla function HSLA color parser

---@class color_converter.formatters
---@field hex function Hex formatter
---@field rgb function RGB formatter
---@field rgba function RGBA formatter
---@field hsl function HSL formatter
---@field hsla function HSLA formatter
