# My Neovim Configuration

> [!WARNING]
> This is my personal Neovim configuration. It's tailored to my workflow and includes many aesthetic choices that may not suit everyone. Feel free to snoop around, take inspiration, and borrow whatever you find useful, but I strongly advise against cloning it wholesale unless you're prepared to maintain it.

A highly personalized and feature-rich Neovim setup built with care. This configuration is designed to be both beautiful and functional, leveraging the power of Lua to create a fast and modern editing experience.

## Core Philosophy

The goal is not to create a one-size-fits-all IDE, but rather a comfortable and efficient environment for coding. The configuration is heavily modularized, making it easy to understand, customize, and extend. The secret sauce is a collection of custom utility functions located in `lua/utils`, which wire everything together.

## Structure Overview

The configuration is organized logically to separate concerns and promote maintainability.

-   `init.lua`: The main entry point.
-   `lua/config/`: Core Neovim settings, including options, keymaps, and autocmds.
-   `lua/plugins/`: Plugin specifications managed by [lazy.nvim](https://github.com/folke/lazy.nvim). This directory is further organized by plugin category (e.g., `ui`, `lsp`, `editor`).
-   `lua/utils/`: A custom library of helper functions that provides the backbone for the entire configuration. This is where much of the unique behavior is defined.
-   `after/ftplugin/`: Filetype-specific settings.
-   `after/lsp/`: Custom configurations for specific LSP servers.

## Key Features & Plugins

This configuration is built upon a curated selection of high-quality plugins.

### Plugin Management

-   **[lazy.nvim](https://github.com/folke/lazy.nvim)**: A modern and fast plugin manager for Neovim. Plugins are defined in `lua/plugins/`.

### User Interface

-   **Dynamic Colorschemes**: The active colorscheme is loaded dynamically. Supported themes include `onedarkpro`, `rose-pine`, and `catppuccin`.
-   **[lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)**: A blazing fast and configurable statusline.
-   **[bufferline.nvim](https://github.com/akinsho/bufferline.nvim)**: Stylish buffer tabs.
-   **[noice.nvim](https://github.com/folke/noice.nvim)**: A complete UI replacement for the Neovim command line and messages.
-   **[neotree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)**: A modern file explorer.
-   **[mini.indentscope](https://github.com/echasnovski/mini.indentscope)**: For visualizing indentation levels.

### LSP, Linting & Formatting

-   **[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)**: The official collection of LSP configurations.
-   **[mason.nvim](https://github.com/williamboman/mason.nvim)**: To easily manage LSP servers, DAP servers, linters, and formatters.
-   **[conform.nvim](https://github.com/stevearc/conform.nvim)**: A lightweight and opinionated formatter plugin.
-   **[nvim-lint](https://github.com/mfussenegger/nvim-lint)**: An asynchronous linter plugin.
-   **[trouble.nvim](https://github.com/folke/trouble.nvim)**: A pretty list for diagnostics, references, and more.

### Editing & Navigation

-   **[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)**: For advanced syntax highlighting and language parsing.
-   **[flash.nvim](https://github.com/folke/flash.nvim)**: For lightning-fast navigation within the visible screen.
-   **[mini.nvim](https://github.com/echasnovski/mini.nvim)**: A collection of minimal and fast Lua modules, including `mini.pairs`, `mini.surround`, and `mini.align`.
-   **[Comment.nvim](https://github.com/numToStr/Comment.nvim)**: Smart and powerful commenting.

### AI Integration

-   **[copilot.lua](https://github.com/github/copilot.vim)**: GitHub Copilot integration.

## Installation

1.  **Clone the repository:**
    ```sh
    git clone <your-repo-url> ~/.config/nvim
    ```
2.  **Dependencies:**
    -   [Nerd Font](https://www.nerdfonts.com/) (for icons)
    -   `ripgrep` (for searching)
    -   `fd` (for finding files)
3.  **Launch Neovim:**
    Open Neovim. `lazy.nvim` will automatically install the plugins.

## Customization

To truly make this configuration your own, I recommend exploring the following files and directories:

-   `lua/utils/init.lua`: Understand the helper functions available.
-   `lua/config/keymaps.lua`: See and modify the keybindings.
-   `lua/plugins/`: Add, remove, or configure plugins to your liking.

Happy hacking!
