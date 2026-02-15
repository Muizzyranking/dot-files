local M = {}

---@type string[]
M.default_servers = {
  "bashls",
  "lua_ls",
  "html",
  "jsonls",
  "clangd",
  "emmet_language_server",
  "gopls",
  "qmlls",
}

---@type string[]
M.ft_modules = { "python", "typescript" }

---@param ft string
---@return table<string, any>
local function load_ft(ft)
  local ok, mod = pcall(require, "config.lsp.servers." .. ft)
  if not ok then
    Utils.notify.warn(string.format("Failed to load server config for '%s': %s", ft, mod), { title = "LSP Registry" })
    return {}
  end
  return mod
end

function M.setup()
  local servers = vim.deepcopy(M.default_servers)

  for _, ft in ipairs(M.ft_modules) do
    local ft_servers = load_ft(ft)
    for server_name, server_opts in pairs(ft_servers) do
      if server_opts.enabled ~= false then
        table.insert(servers, server_name)
      end
      if server_opts.keys then
        Utils.map.set(server_opts.keys, { lsp = { name = server_name } })
      end
    end
  end

  if #servers > 0 then
    local success, err = pcall(vim.lsp.enable, servers, true)
    if not success then
      Utils.notify.error("Failed to enable LSP servers: " .. tostring(err), { title = "LSP" })
    end
  end
end

return M
