---@class setup_lang.add_ft
---@field extension? table<string, string> # Map specific extensions to filetypes
---@field filename? table<string, string> # Map specific filenames to filetypes
---@field pattern? table<string, string> # Regex patterns to match file paths and assign filetypes
---@field filetype? table<string, string> # Custom filetype mapping

---@class setup_lang.autocmd
---@field events? string|string[] # The event(s) to trigger on
---@field group? string|integer # The group name or ID for the autocmd
---@field pattern? string|string[] # The pattern(s) to match
---@field command? string # The command to run
---@field callback? fun(args: table) # The callback function to run

---@class setup_lang.lspconfig
---@field servers lspconfig.options # Server configurations
---@field setup? table<string, fun(server:string, opts:_.lspconfig.options):boolean?> # Setup functions

---@class setup_lang.formatting
---@field formatters? table<string, conform.FormatterConfigOverride|fun(bufnr: number): nil|conform.FormatterConfigOverride> # Custom formatters and overrides for built-in formatters.
---@field formatters_by_ft? table<string, conform.FiletypeFormatter> # Map of filetype to formatters
---@field format_on_save? boolean # Whether to format on save
---@field use_prettier_biome? boolean|string[] # Whether to use prettier for this filetypes or use prettier for specific filetypes

---@class setup_lang.linting
---@field linters_by_ft? table<string, string[]> # Linters by filetype
---@field linters? table<string, lint.Linter|fun():lint.Linter> # linters

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

---@alias KeymapMode
---| '"n"' # Normal mode
---| '"i"' # Insert mode
---| '"v"' # Visual mode
---| '"x"' # Visual block mode
---| '"s"' # Select mode
---| '"o"' # Operator pending mode
---| '"t"' # Terminal mode
---| '"c"' # Command mode

---@class map.ToggleOpts.IconConf
---@field enabled? string Icon to display when feature is enabled
---@field disabled? string Icon to display when feature is disabled

---@class map.KeymapOpts
---@field [1] string # The left-hand side of the mapping
---@field [2] string|function # The right-hand side of the mapping
---@field mode? KeymapMode|KeymapMode[] # Vim mode(s) for the mapping
---@field desc? string|function # Description of the mapping
---@field buffer? number # Buffer number for buffer-local mapping
---@field silent? boolean # Whether the mapping should be silent
---@field remap? boolean # Whether the mapping should be remappable
---@field expr? boolean # Whether the mapping is an expression
---@field icon? string|table # Icon for which-key integration
---@field conds table<number, function|boolean> # Conditions for the mapping

---@class map.ToggleOpts
---@field [1] string # The left-hand side of the mapping
---@field name? string # Name of the toggle
---@field get_state fun(buf?: number):  boolean # returns the current state
---@field change_state fun(state: boolean, buf?: number) # Function to change the state
---@field mode? KeymapMode|KeymapMode[] # Vim mode(s) for the mapping
---@field desc? string|fun(state: boolean): string # Description of the mapping
---@field icon? map.ToggleOpts.IconConf # Icon configuration
---@field color? map.ToggleOpts.IconConf # Color configuration
---@field notify? boolean # Whether to show notifications
---@field set_key? boolean # Whether to set the keymap immediately
---@field [string] any # Additional fields to pass to the keymap

---@class map.ReloadConfig
---@field cmd string # Command to reload the configuration
---@field buffer number # Buffer number to reload
---@field title? string # Title for the notification
---@field restart? boolean # Whether to restart the service
---@field cond? fun(): boolean # Condition function to check if the command should be run

---@class autocmd.Create
---@field callback? fun(event: table) # Callback function for the autocmd
---@field cmd? string # Command to run when the autocmd is triggered
---@field pattern? string|string[] # Pattern(s) to match for the autocmd
---@field group? string|integer # Group name or ID for the autocmd
---@field once? boolean # Whether the autocmd should only run once
---@field desc? string # Description of the autocmd
---@field events? string|string[]

---@class utils.run_command_opts
---@field input? string
---@field trim? boolean
---@field error_handler? fun(output: string, exit_code: number)

---@class word_cycle.CycleList
---@field [integer] string

---@class word_cycle.FiletypeCycle
---@field [string] word_cycle.CycleList[]

---@class word_cycle.CycleEntry
---@field list word_cycle.CycleList
---@field current_index integer

--- @class word_cycle.CycleLookup
--- @field [string] word_cycle.CycleEntry

---@class word_cycle.Config
---@field global_cycle? word_cycle.CycleList[]
---@field filetype_cycle? word_cycle.FiletypeCycle
---@field keymap? string|false
