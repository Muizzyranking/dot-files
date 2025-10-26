---@alias map.KeymapMode
---| "n" # Normal mode
---| "i" # Insert mode
---| "v" # Visual mode
---| "x" # Visual block mode
---| "s" # Select mode
---| "o" # Operator pending mode
---| "t" # Terminal mode
---| "c" # Command mode

---@alias map.AbbrevConds
---| "lsp_keyword"

---@class map.IconConfig
---@field icon string # Icon character/text
---@field color string # Icon color

---@class map.ToggleIconConfig
---@field enabled? string # Icon when feature is enabled
---@field disabled? string # Icon when feature is disabled

---@class map.ToggleColorConfig
---@field enabled? string # Color when feature is enabled (e.g., "green")
---@field disabled? string # Color when feature is disabled (e.g., "yellow")

---@class map.ToggleOpts.IconConf
---@field enabled? string Icon to display when feature is enabled
---@field disabled? string Icon to display when feature is disabled

---@class map.KeymapOpts
---@field [1] string # The left-hand side of the mapping
---@field [2] string|function # The right-hand side of the mapping
---@field mode? map.KeymapMode|map.KeymapMode[] # Vim mode(s) for the mapping
---@field desc? string|function # Description of the mapping
---@field buffer? number # Buffer number for buffer-local mapping
---@field silent? boolean # Whether the mapping should be silent
---@field remap? boolean # Whether the mapping should be remappable
---@field expr? boolean # Whether the mapping is an expression
---@field icon? string|map.IconConfig # Icon for which-key integration
---@field conds? table<number, function|boolean> # Conditions for the mapping

---@class map.ToggleOpts : map.KeymapOpts
---@field name string # Name of the toggle (required for notifications unless notify=false)
---@field get_state fun(buf?: number): boolean # Function that returns the current state
---@field change_state fun(state: boolean, buf?: number) # Function to change the state
---@field icon? map.ToggleIconConfig # Icon configuration for different states
---@field color? map.ToggleColorConfig # Color configuration for different states
---@field notify? boolean # Whether to show notifications (default: true)
---@field set_key? boolean # Whether to set the keymap immediately (default: true)

---@class map.ReloadConfig
---@field cmd string # Command to reload/restart the configuration
---@field buffer? number # Buffer number for buffer-local mapping (default: 0)
---@field key? string # Keymap to trigger the reload (default: "<leader>rr")
---@field title? string # Title for the notification (default: "Config")
---@field restart? boolean # Whether to restart the service instead of just reloading
---@field cond? boolean|function # Condition to check if the command should be set

---@class map.AbbrevOpts
---@field mode? string # Mode for the abbreviation (default: "ia")
---@field conds? map.AbbrevConds|function|(map.AbbrevConds|function)[] # Conditions to check before applying abbreviation
---@field expr? boolean # Whether to treat as expression mapping
---@field buffer? number # Buffer number for buffer-local abbreviation
---@field desc? string # Description for the abbreviation
---@field silent? boolean # Whether to silence the abbreviation
---@field noremap? boolean # Whether to use noremap
---@field nowait? boolean # Whether to use nowait

---@class map.Abbrevs
---@field [1] string # The correct word/replacement
---@field [2] string|string[] # The word(s) to abbreviate (misspellings)
---@field [3]? map.AbbrevOpts # Optional abbreviation-specific options

---@class autocmd.Create
---@field merge_events? boolean # Whether to merge provided events with existing ones
---@field callback? fun(event: table) # Callback function for the autocmd
---@field command? string # Command to run when the autocmd is triggered
---@field pattern? string|string[] # Pattern(s) to match for the autocmd
---@field group? string|integer # Group name or ID for the autocmd
---@field once? boolean # Whether the autocmd should only run once
---@field desc? string # Description of the autocmd
---@field events? string|string[]

---@class utils.run_command_opts
---@field input? string
---@field trim? boolean
---@field callback? fun(output: string, success: boolean, exit_code: number)

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

---@class BigFileConfig
---@field size number File size threshold in bytes (default: 1.5MB)
---@field max_lines number Maximum line count threshold (default: 32768)
---@field avg_line_length number Average line length threshold (default: 1000)
---@field sample_lines number Number of lines to sample for avg calculation (default: 100)
