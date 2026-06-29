---@class Statusline.Sep
---@field left? string
---@field right? string

---@class Statusline.ComponentCacheOpts
---@field events (string|Statusline.Utils.CacheEvent)[]
---@field per_buf? boolean

---@class Statusline.Component
---@field render fun(): string|nil
---@field hl? Statusline.Hl
---@field fill? boolean
---@field sep? Statusline.Sep
---@field raw? boolean

---@class Statusline.ComponentOpts
---@field render fun(): string|nil
---@field hl? Statusline.Hl
---@field fill? boolean
---@field sep? Statusline.Sep
---@field raw? boolean
---@field cache? Statusline.ComponentCacheOpts

---@class Statusline.LabelOpts
---@field hl? Statusline.Hl
---@field fill? boolean

---@class Statusline.Layout
---@field left Statusline.Component[]
---@field center Statusline.Component[]
---@field right Statusline.Component[]

---@class Statusline.HlSpec
---@field fg? string
---@field bg? string
---@field bold? boolean
---@field italic? boolean
---@field underline? boolean

---@alias Statusline.Hl string|Statusline.HlSpec|fun(): string|Statusline.HlSpec

---@class Statusline.Utils.CacheOpts
---@field per_buf? boolean

---@class Statusline.Utils.CacheEvent
---@field event string
---@field pattern? string

---@meta

---@class Statusline.Config
---@field default_fill_sep string
---@field default_component_bg string   bg applied to components when hl is a table (or table with only fg)
---@field default_component_fg string   fg applied to components when hl is a table with only bg

---@class Statusline.ResolveContext
---@field fill? boolean   true → bg comes from mode color, not default_component_bg
