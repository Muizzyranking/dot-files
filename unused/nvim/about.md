# About My Neovim Configuration

## Overview

This is a highly customized Neovim configuration built around modern Lua-based plugin management with `lazy.nvim`. The configuration follows a modular architecture that prioritizes performance, extensibility, and a rich development experience.

## Architecture & Philosophy

### Core Principles

1. **Modular Design**: Everything is organized into logical modules under `lua/config/` and `lua/plugins/`
2. **Lazy Loading**: Plugins are loaded on-demand to minimize startup time
3. **Performance First**: Features that impact startup performance are carefully managed
4. **Rich UX**: Modern UI components and smooth interactions
5. **Extensible**: Easy to add new plugins and functionality

### Directory Structure

```
nvim/
├── init.lua                    # Entry point
├── lua/
│   ├── config/                 # Core configuration modules
│   │   ├── init.lua           # Main config loader
│   │   ├── options.lua        # Vim options
│   │   ├── keymaps.lua        # Global keymaps
│   │   ├── autocmd.lua        # Auto commands
│   │   └── lazy.lua           # Lazy.nvim configuration
│   ├── plugins/               # Plugin specifications
│   │   ├── core/             # Core plugins (snacks.nvim)
│   │   ├── lsp/              # LSP-related plugins
│   │   ├── ui/               # UI plugins
│   │   ├── editor/           # Editor enhancements
│   │   ├── ai/               # AI assistants
│   │   └── extras/           # Language-specific extras
│   └── utils/                 # Utility modules
│       ├── init.lua          # Main utilities loader
│       ├── bigfile.lua       # Large file handling
│       ├── lsp.lua           # LSP utilities
│       └── ...
├── after/                     # After-plugin configurations
└── queries/                   # Treesitter queries
```

## Key Components

### 1. Plugin Management (lazy.nvim)

- **Lazy Loading**: Most plugins load on specific events or commands
- **Performance Tuning**: Disabled RTP plugins, optimized defaults
- **Change Detection**: Disabled to prevent unnecessary checks

### 2. Core Framework (snacks.nvim)

The configuration is built around `folke/snacks.nvim` as the central framework:

- **Dashboard**: Custom startup screen with quick actions
- **Status Column**: Integrated line numbers and diagnostics
- **Picker**: File search and navigation
- **Explorer**: File tree functionality
- **Input**: Enhanced input UI
- **Scroll**: Smooth scrolling
- **Notifier**: Notification system

### 3. LSP & Completion

- **Blink.cmp**: Fast completion engine with Rust backend
- **Mason**: LSP server management
- **Conform**: Code formatting
- **nvim-lint**: Linting support
- **Trouble**: Diagnostics viewer

### 4. UI Ecosystem

- **Noice.nvim**: Command line and UI replacement
- **Bufferline**: Tab-style buffer management
- **Lualine**: Status line with rich information
- **Colorizer**: Live color preview
- **Rose Pine**: Primary colorscheme

### 5. Editor Enhancements

- **Flash.nvim**: Quick navigation
- **Treesitter**: Syntax highlighting and code understanding
- **Git integration**: Gitsigns, Git-related tools
- **Mini plugins**: Pairs, surround, align, AI
- **Oil.nvim**: File editing

### 6. AI Integration

- **Copilot.lua**: GitHub Copilot integration
- **Sidekick**: AI assistant for code generation

## Performance Features

### Big File Handling

The configuration includes sophisticated big file detection and handling:

- **Size-based detection**: Files > 1.5MB
- **Line count detection**: Files > 32,768 lines
- **Average line length detection**: Lines > 1000 chars
- **Automatic feature disabling**: Treesitter, LSP, copilot for large files
- **Optimized settings**: Manual folds, disabled syntax for large files

### Lazy Loading Strategy

- **Event-based loading**: Plugins load on specific events (VeryLazy, InsertEnter, etc.)
- **Command-based loading**: Heavy plugins load only when needed
- **Filetype-specific loading**: Language tools load only for relevant filetypes
- **Conditional loading**: Some features depend on system capabilities

### Startup Optimization

- **Disabled RTP plugins**: Removed unused Vim plugins
- **Optimized autocmds**: Grouped and efficient event handling
- **Deferred loading**: Non-critical features load after UI is ready
- **Memoization**: Cached expensive computations

## Custom Utilities

The configuration includes several custom utility modules:

### Utils Framework

- **Utils.autocmd**: Enhanced autocmd management
- **Utils.lsp**: LSP client utilities
- **Utils.treesitter**: Treesitter helpers
- **Utils.map**: Keymap management with which-key integration
- **Utils.root**: Project root detection
- **Utils.hl**: Highlight management
- **Utils.ui**: UI utilities and theming

### Special Features

- **Logo system**: Dynamic ASCII art for dashboard
- **Discipline**: Keymap mistake tracking
- **Git integration**: Enhanced git workflows
- **Session management**: Persistence with smart window cleanup
- **Configuration reloading**: Hot-reload for config files

## Keybind Philosophy

The configuration follows a consistent keybinding philosophy:

- **Leader key**: `<Space>` as primary leader
- **Which-key integration**: Automatic keybinding documentation
- **Modal consistency**: Similar patterns across modes
- **Mnemonic organization**: Logical grouping of related functions

## Colorscheme & Theming

- **Primary**: Rose Pine (moon variant)
- **Transparency**: Enabled for supported terminals
- **Custom highlights**: Language-specific color adjustments
- **Icon integration**: Nerd Font icons throughout
- **Consistent theming**: Unified color experience across plugins

## Language Support

Built-in support for:

- **Web**: TypeScript, JavaScript, React, Vue, HTML, CSS
- **Systems**: C, C++, Rust, Go
- **Scripting**: Python, Lua, Bash, Shell
- **Config**: YAML, TOML, JSON
- **Documentation**: Markdown, LaTeX

## Session Management

- **Persistence**: Automatic session saving/restoration
- **Smart cleanup**: Removes empty windows on session load
- **State preservation**: Maintains editor state across restarts
- **Buffer management**: Intelligent buffer handling

## Development Workflow

The configuration is designed for modern development workflows:

- **Git integration**: Seamless git operations
- **LSP-powered**: Rich language intelligence
- **Quick navigation**: Fast file and symbol jumping
- **Code actions**: Context-aware refactoring
- **Debugging support**: Integrated debugging capabilities

## Extensibility

The configuration is built to be easily extended:

- **Plugin templates**: Standardized plugin specifications
- **Utility functions**: Reusable helper functions
- **Autocmd patterns**: Consistent event handling
- **Configuration patterns**: Standardized option management

This configuration represents a balance between feature richness and performance, with careful attention to startup time and runtime efficiency.