_G.Utils = require("utils")
_G.P = function(...)
  vim.print(vim.inspect(...))
end
Utils.hl.setup()
require("config.options")
require("config.lazy")
local lazy_autocmds = vim.fn.argc(-1) == 0

local function try(fn, opts)
  opts = type(opts) == "string" and { msg = opts } or opts or {}
  local ok, result = xpcall(fn, function(err)
    local msg = opts.msg and (opts.msg .. "\n\n" .. err) or err
    if opts.on_error then
      opts.on_error(msg)
    else
      vim.schedule(function()
        Utils.notify.error(msg, opts)
      end)
    end
    return err
  end)
  return ok and result or nil
end

local function load(name)
  local mod = "config." .. name
  if require("lazy.core.cache").find(mod)[1] then
    try(function()
      require(mod)
    end, { msg = "Failed loading " .. mod })
  end
end

if not lazy_autocmds then
  load("autocmds")
end

local group = vim.api.nvim_create_augroup("config.init", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "VeryLazy",
  callback = function()
    if lazy_autocmds then
      load("autocmds")
    end
    load("keymaps")
    load("lsp")
    Utils.map.setup()
    Utils.format.setup()
    load("filetypes")
    vim.schedule(function()
      load("abbrevations")
    end)
  end,
})
vim.cmd.colorscheme("ember")
