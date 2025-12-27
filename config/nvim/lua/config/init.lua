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
  local msg = opts.msg
  local error_handler = function(err)
    msg = (msg and (msg .. "\n\n") or "") .. err
    if opts.on_error then
      opts.on_error(msg)
    else
      vim.schedule(function()
        Utils.notify.error(msg, opts)
      end)
    end
    return err
  end
  local ok, result = xpcall(fn, error_handler)
  return ok and result or nil
end

local function load(name)
  local function _load(mod)
    if require("lazy.core.cache").find(mod)[1] then
      try(function()
        require(mod)
      end, { msg = "Failed loading " .. mod })
    end
  end
  _load("config." .. name)
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
    Utils.map.abbrev({
      { "don't", "dont" },
      { "Don't", "Dont" },
      { "local", { "lcaol", "lcoal", "locla" } },
      { "share", { "saher", "sahre" } },
      { "blame", { "balme" } },
      { "return", { "Return" } },
    }, {})
    vim.filetype.add({
      extension = { rasi = "rasi", rofi = "rasi", wofi = "rasi", sh = "sh" },
      filename = {
        ["vifmrc"] = "vim",
        [".gitconfig"] = "gitconfig",
        [".gitignore"] = "gitignore",
        [".gitignore_global"] = "gitignore",
      },
      pattern = {
        [".*/waybar/config"] = "jsonc",
        [".*/kitty/.+%.conf"] = "bash",
        [".*/hypr/.+%.conf"] = "hyprlang",
        ["%.env%.[%w_.-]+"] = "sh",
        [".*git/config.*"] = "gitconfig",
        [".*git/ignore.*"] = "gitignore",
        [".*gitconfig.*"] = "gitconfig",
        [".*gitignore.*"] = "gitignore",
      },
    })
  end,
})
