# Performance Optimization Guide

## Current Performance Issues

Based on analysis of your Neovim configuration, the main startup delay and UI freezing is likely caused by several factors:

1. **Heavy plugin loading on startup**
2. **Complex autocmd chains**
3. **Multiple UI components initializing simultaneously**
4. **LSP and Treesitter setup overhead**

## Immediate Performance Improvements

### 1. Optimize Plugin Loading

**Problem**: Many plugins load on `VeryLazy` event, causing UI delays

**Solution**: Make more plugins truly lazy:

```lua
-- In lua/plugins/ui/bufferline.lua
- event = { "VeryLazy" },
+ event = { "BufReadPost" }, -- Load only when reading files

-- In lua/plugins/editor/flash.lua  
- event = { "VeryLazy" },
+ keys = { "s", "S", "r", "R" }, -- Load only when using keys
```

### 2. Disable Unnecessary Features

**Remove or disable these performance-heavy plugins:**

```lua
-- In lua/plugins/core/snacks.lua
opts = {
  bigfile = { enabled = false }, -- Already disabled ✓
  image = { enabled = false },   -- Disable if not using images
  words = { enabled = false },   -- Disable if not using word frequency
  scroll = { enabled = false },  -- Try disabling smooth scrolling
}
```

### 3. Optimize Treesitter

**Problem**: Too many parsers installed and loading eagerly

**Solution**:

```lua
-- In lua/plugins/lsp/nvim-treesitter.lua
opts = {
  ensure_installed = {
    -- Keep only essential parsers
    "vim", "vimdoc", "query", "lua", "python",
    "javascript", "typescript", "html", "css", "json"
  },
  highlight = {
    enable = true,
    disable = function(lang, buf)
      -- Disable for large files
      return vim.b[buf].bigfile
    end,
  },
}
```

### 4. Optimize Noice.nvim

**Problem**: Noice has extensive route filtering that impacts performance

**Solution**:

```lua
-- In lua/plugins/ui/noice.lua
opts = {
  lsp = {
    progress = { enabled = false }, -- Disable progress notifications
    signature = { enabled = false }, -- Disable if not using
  },
  presets = {
    bottom_search = false,    -- Disable bottom search
    command_palette = false,   -- Disable command palette
    inc_rename = false,       -- Disable incremental rename
  },
  -- Remove most routes - keep only essential ones
  routes = {
    {
      filter = { event = "notify", find = "No information available" },
      opts = { skip = true },
    },
  },
}
```

### 5. Optimize Autocmds

**Problem**: Too many autocmds running on every event

**Solution**: Reduce autocmd frequency:

```lua
-- In lua/config/autocmd.lua
-- Remove or comment out non-essential autocmds:

-- Remove this - runs on every buffer change
-- autocmd("BufEnter", { command = [[set formatoptions-=cro]] })

-- Optimize the toggle relative numbers autocmd
autocmd.autocmd_augroup("toggle_rel_number", {
  {
    events = { "WinEnter", "WinLeave" }, -- Remove BufEnter/BufLeave
    pattern = "*",
    callback = function()
      -- Simplified logic
    end,
  },
})
```

## Configuration Changes

### 1. Lazy.nvim Performance Settings

```lua
-- In lua/config/lazy.lua
require("lazy").setup({
  -- Add these performance settings
  dev = {
    path = "~/projects",
    fallback = true,
  },
  install = {
    missing = true,
    colorscheme = { Utils.ui.colorscheme },
  },
  ui = {
    size = { width = 0.8, height = 0.8 }, -- Smaller UI
  },
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true,
    rtp = {
      reset = true,
      -- Add more disabled plugins
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
        "osc52", "rplugin", "editorconfig", "man",
        "shada_plugin", "spellfile_plugin", "tarPlugin",
      },
    },
  },
})
```

### 2. Options Optimization

```lua
-- In lua/config/options.lua
-- Remove or comment out these expensive options:

-- opt.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]
-- Replace with simpler statuscolumn if needed

-- opt.smoothscroll = true -- Can cause performance issues
-- opt.foldmethod = "indent" -- Expensive for large files
```

### 3. Big File Configuration

```lua
-- In lua/utils/bigfile.lua
-- Lower the thresholds for big file detection
local function get_config()
  vim.g.bigfile = vim.g.bigfile or 500 * 1024 -- 500KB instead of 1.5MB
  vim.g.bigfile_max_lines = vim.g.bigfile_max_lines or 10000 -- 10K instead of 32K
  -- ... rest of config
end
```

## Plugin Removal Recommendations

### Safe to Remove:

1. **Mini plugins** - You have multiple mini plugins that overlap:
   - `mini-align` (use flash.nvim instead)
   - `mini-ai` (use treesitter text objects instead)
   - `mini-surround` (keep this one, it's useful)

2. **Yanky.nvim** - If you don't need advanced yank management

3. **Treesj** - If you don't use tree splitting frequently

4. **Colorizer** - Can be slow, disable if not essential

5. **Rainbow delimiters** - Purely cosmetic, can impact performance

### Conditional Loading:

```lua
-- Load these only when needed
{
  "folke/flash.nvim",
  keys = { "s", "S", "r", "R" }, -- Already good ✓
},

{
  "nvim-treesitter/nvim-treesitter-textobjects",
  event = { "BufReadPost" }, -- Instead of VeryLazy
},
```

## Startup Sequence Optimization

### 1. Defer Non-Critical Features

```lua
-- In lua/config/init.lua
Utils.autocmd.on_very_lazy(function()
  if LazyLoad then r("autocmd") end
  r("keymaps")
  r("abbrevations")
  r("filetype")
  
  -- Defer these
  vim.schedule(function()
    Utils.root.setup()
    Utils.map.setup()
    Utils.discipline.setup()
    Utils.git.setup()
  end)
end, { group = "LazyModules" })
```

### 2. Optimize Dashboard Loading

```lua
-- In lua/plugins/ui/snacks_dashboard.lua
return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.dashboard = {
      -- Simplify dashboard
      preset = {
        header = Utils.ui.logo,
        keys = {
          -- Keep only essential keys
          { icon = " ", key = "n", desc = "New File", action = ":enew" },
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    }
  end,
}
```

## LSP Optimization

### 1. Conditional LSP Loading

```lua
-- In lua/plugins/lsp/lspconfig.lua
-- Add conditional loading for LSP servers
{
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- Only setup LSP for certain filetypes
    local filetypes = { "python", "javascript", "typescript", "lua", "go", "rust" }
    if not vim.tbl_contains(filetypes, vim.bo.filetype) then
      return
    end
    -- ... rest of LSP setup
  end,
}
```

### 2. Blink.cmp Optimization

```lua
-- In lua/plugins/lsp/blink.lua
opts = {
  completion = {
    documentation = {
      auto_show = false, -- Disable auto documentation
    },
    ghost_text = {
      enabled = false,   -- Disable ghost text
    },
  },
  signature = {
    enabled = false,    -- Already disabled ✓
  },
}
```

## Monitoring Performance

### 1. Startup Time Analysis

```bash
# Measure startup time
nvim --startuptime startup.log +q && tail -n 20 startup.log

# Check which plugins are slow
nvim --startuptime startup.log +qa && sort -k2 -nr startup.log | head -20
```

### 2. Runtime Performance

Add this to your config to monitor performance:

```lua
-- In lua/config/profiler.lua
if vim.env.NVIM_PROFILER then
  local profiler = require("snacks.profiler")
  profiler.start({
    -- Only profile specific events
    events = { "BufRead", "BufWrite", "LspAttach" },
  })
end
```

## Recommended Changes Summary

### High Priority:
1. Disable Noice presets (bottom_search, command_palette, inc_rename)
2. Reduce Treesitter parsers to essential ones only
3. Lower big file thresholds
4. Make more plugins truly lazy (keys-based loading)
5. Simplify autocmds

### Medium Priority:
1. Remove mini-align, mini-ai, colorizer, rainbow-delimeters
2. Disable snacks words, scroll, image
3. Optimize LSP loading conditions
4. Simplify dashboard

### Low Priority:
1. Remove treesj if not used frequently
2. Optimize blink.cmp settings
3. Add performance monitoring

## Expected Results

After implementing these changes:

- **Startup time**: Should reduce from 3-5 seconds to 1-2 seconds
- **UI responsiveness**: Dashboard should appear immediately
- **Memory usage**: Should reduce by 20-30%
- **Runtime performance**: Smoother editing experience

## Testing Changes

1. Make changes incrementally and test startup time
2. Use `nvim --startuptime` to measure improvements
3. Test with your typical workflow to ensure functionality is preserved
4. Monitor memory usage with `:lua print(collectgarbage("count"))`

The key is finding the right balance between features and performance for your specific needs.