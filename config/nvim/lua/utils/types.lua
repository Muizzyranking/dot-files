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

---@class map.ToggleIconConfig
---@field enabled? string # Icon when feature is enabled
---@field disabled? string # Icon when feature is disabled

---@class map.ToggleColorConfig
---@field enabled? string # Color when feature is enabled (e.g., "green")
---@field disabled? string # Color when feature is disabled (e.g., "yellow")

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

---@class map.BaseMapping
---@field [1] string # The left-hand side of the mapping
---@field mode? map.KeymapMode|map.KeymapMode[]
---@field desc? string|function
---@field buffer? number|boolean
---@field silent? boolean
---@field remap? boolean
---@field expr? boolean
---@field icon? table
---@field lsp? table<string, string>
---@field has? string|string[]
---@field conds? table<number, function|boolean>

---@class map.KeymapOpts : map.BaseMapping
---@field [2] string|function # The right-hand side of the mapping

---@class toggle.Opts : map.BaseMapping
---@field name? string
---@field get fun(buf?: number): boolean
---@field set fun(state: boolean, buf?: number)
---@field icon? map.ToggleIconConfig
---@field color? map.ToggleColorConfig
---@field notify? boolean
---@field set_key? boolean
