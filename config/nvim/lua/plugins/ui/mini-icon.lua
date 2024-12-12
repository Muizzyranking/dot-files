return {
  "echasnovski/mini.icons",
  init = function()
    package.preload["nvim-web-devicons"] = function()
      require("mini.icons").mock_nvim_web_devicons()
      return package.loaded["nvim-web-devicons"]
    end
  end,
  opts = {
    file = {
      [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
    },
    filetype = {
      dotenv = { glyph = "", hl = "MiniIconsYellow" },
      -- FIX: doesnt work
      htmldjango = { glyph = "", hl = "MiniIconsBlue" },
    },
  },
}
