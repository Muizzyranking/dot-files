local function get_unsaved_buffers()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      local name = vim.api.nvim_buf_get_name(buf)
      local display_name = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":~:.")
      table.insert(buffers, {
        buf = buf,
        text = display_name,
        filename = name,
        idx = buf,
      })
    end
  end
  return buffers
end

---@type snacks.picker.Config
return {
  title = "Unsaved Buffers",

  finder = function()
    return get_unsaved_buffers()
  end,

  format = function(item)
    local ret = {}
    local icon, icon_hl = Snacks.util.icon(item.filename)
    ret[#ret + 1] = { icon .. " ", icon_hl }
    ret[#ret + 1] = { item.text }
    return ret
  end,

  actions = {
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.api.nvim_set_current_buf(item.buf)
      end
    end,

    save = function(picker, item)
      if not item then
        return
      end
      local ok = pcall(function()
        vim.api.nvim_buf_call(item.buf, function()
          vim.cmd("write")
        end)
      end)
      if ok then
        vim.notify("Saved: " .. item.text, vim.log.levels.INFO)
        picker:find({
          on_done = function()
            if picker:count() == 0 then
              picker:close()
              vim.notify("All buffers saved!", vim.log.levels.INFO)
            end
          end,
        })
      else
        vim.notify("Failed to save: " .. item.text, vim.log.levels.ERROR)
      end
    end,

    save_all = function(picker)
      local buffers = get_unsaved_buffers()
      local saved = 0
      for _, buf_item in ipairs(buffers) do
        local ok = pcall(function()
          vim.api.nvim_buf_call(buf_item.buf, function()
            vim.cmd("write")
          end)
        end)
        if ok then
          saved = saved + 1
        end
      end
      vim.notify(("Saved %d buffer(s)"):format(saved), vim.log.levels.INFO)
      picker:find({
        on_done = function()
          if picker:count() == 0 then
            picker:close()
          end
        end,
      })
    end,
  },

  ---@diagnostic disable-next-line: assign-type-mismatch
  layout = { preset = "drop", preview = false },

  on_show = function()
    vim.cmd("stopinsert")
  end,

  win = {
    input = {
      keys = {
        ["<c-s>"] = { "save", mode = { "n", "i" } },
        ["<c-a>"] = { "save_all", mode = { "n", "i" } },
      },
    },
  },
}
