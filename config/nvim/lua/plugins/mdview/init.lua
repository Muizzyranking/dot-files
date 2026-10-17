--- Markdown preview that opens in its own Chrome app window.
---
--- What it does:
---   Renders the current markdown buffer with cmark-gfm and shows it in a Chrome window
---   started in --app mode. The window has no tabs, address bar, or bookmarks. It stays
---   in sync with the cursor and with edits, and it closes when the session ends.
---
--- Why it exists:
---   Most preview plugins open their page as a tab in your existing Chrome session. I
---   wanted a separate, disposable window instead: its own profile, no browser chrome,
---   and it goes away on its own when you stop the preview or close the window. That
---   keeps it out of your browsing session and makes the preview feel like part of the
---   editor.
---
--- Usage:
---   require("plugins.mdv").setup({ keymap = "<leader>mp" })
---
--- This is a plain module. Nothing runs until setup() is called, and the heavy modules
--- (server, render, browser) load only when a preview starts.
---@class mdview
local M = {}

local api = require("plugins.mdview.api")

M.setup = api.setup
M.start = api.start
M.stop = api.stop
M.toggle = api.toggle
M.is_active = api.is_active
M.status = api.status

return M
