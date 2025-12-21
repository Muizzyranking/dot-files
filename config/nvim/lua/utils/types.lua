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
---@field lsp? table<string, string> # Conditions for the mapping
---@field has? string|string[] # LSP capabilities required for the mapping

---@class toggle.Opts : map.KeymapOpts
---@field name string # Name of the toggle (required for notifications unless notify=false)
---@field get fun(buf?: number): boolean # Function that returns the current state
---@field set fun(state: boolean, buf?: number) # Function to change the state
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

---@class BigFileConfig
---@field size number File size threshold in bytes (default: 1.5MB)
---@field max_lines number Maximum line count threshold (default: 32768)
---@field avg_line_length number Average line length threshold (default: 1000)
---@field sample_lines number Number of lines to sample for avg calculation (default: 100)

---@class utils.git.WindowOpts
---@field height_frac number
---@field width_frac number
---@field style string
---@field border string|table
---@field title? string
---@field title_pos? "center"|"left"|"right"
---@field footer? string
---@field footer_pos? "center"|"left"|"right"

---@class utils.git.stageOpts
---@field float_win_opts { staging: utils.git.WindowOpts, commit: utils.git.WindowOpts }
---@field default_expanded boolean
---@field icons { outgoing: string, incoming: string, changed: string, untracked: string }

---@class utils.git.File
---@field path string Full path relative to git root
---@field status string Porcelain status code (2 chars, e.g. "M ", " M", "??")
---@field is_dir boolean
---@field children? utils.git.File[]

---@class utils.git.stageStat
---@field ahead integer
---@field behind integer
---@field changes integer
---@field untracked integer

---@class utils.git.stageState
---@field expanded table<string, boolean> Map of path -> expanded state
---@field cursor? { [1]: integer, [2]: integer } Last cursor position

---@class utils.git.stageSessionState
---@field repos table<string, utils.git.stageState>
