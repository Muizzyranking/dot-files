return {
    "nvim-telescope/telescope.nvim", 
    tag = '0.1.5',
    dependencies = { 
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    config = function()
        local actions = require("telescope.actions")
        require("telescope").setup{
            defaults = {
                mappings = {
                    n = {
                        ["q"] = actions.close
                    },
                },
            }
        }
    end,
}
