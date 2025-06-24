return {
  "echasnovski/mini.keymap",
  config = function()
    local mini_key = require("mini.keymap")
    local multistep = mini_key.map_multistep

    multistep("i", "<tab>", { "blink_next", "jump_after_close" })
    multistep("i", "<s-tab>", { "blink_prev", "jump_before_open" })
  end,
}
