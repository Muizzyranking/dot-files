return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    local mouse_scrolled = false
    for _, scroll in ipairs({ "Up", "Down" }) do
      local key = "<ScrollWheel" .. scroll .. ">"
      vim.keymap.set({ "", "i" }, key, function()
        mouse_scrolled = true
        return key
      end, { expr = true })
    end

    -- Disable animations for specific filetypes
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "grug-far",
      callback = function(event)
        vim.b[event.buf].snacks_scroll = false
      end,
    })

    opts.scroll = {
      animate = {
        duration = { step = 15, total = 150 },
        easing = "linear",
      },
      filter = function(buf)
        -- Don't animate when using mouse scroll
        if mouse_scrolled then
          mouse_scrolled = false
          return false
        end
        return vim.g.snacks_scroll ~= false and vim.b[buf].snacks_scroll ~= false and vim.bo[buf].buftype ~= "terminal"
      end,
    }
  end,
}
