return {
    "stevearc/conform.nvim",
    dependencies = {
        { "neovim/nvim-lspconfig" },
        { "nvim-lua/plenary.nvim" },
        { "williamboman/mason.nvim" },
    },
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
        },
        -- If this is set, Conform will run the formatter on save.
        -- It will pass the table to conform.format().
        -- This can also be a function that returns the table.
        format_on_save = {
            -- I recommend these options. See :help conform.format for details.
            lsp_fallback = true,
            timeout_ms = 500,
        },
        -- If this is set, Conform will run the formatter asynchronously after save.
        -- It will pass the table to conform.format().
        -- This can also be a function that returns the table.
        format_after_save = {
            lsp_fallback = true,
        },
        -- Set the log level. Use `:ConformInfo` to see the location of the log file.
        log_level = vim.log.levels.ERROR,
        --     -- Conform will notify you when a formatter errors
        notify_on_error = true,
        --     -- Custom formatters and changes to built-in formatters
    }
}
