return {
  "echasnovski/mini.keymap",
  event = "VeryLazy",
  config = function()
    local mini_key = require("mini.keymap")
    local multistep = mini_key.map_multistep

    multistep("i", "<tab>", { "increase_indent", "jump_after_close" })
    multistep("i", "<s-tab>", { "decrease_indent", "jump_before_open" })
  end,
}
