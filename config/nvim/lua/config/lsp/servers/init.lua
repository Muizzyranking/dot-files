local M = {}

---@param ft string
---@return table<string, any>
local function r(ft)
  local ok, module = pcall(require, "config.lsp.servers." .. ft)
  return ok and module or {}
end

function M.setup()
  local fts = { "python", "typescript" }
  local ft_servers = {}
  for _, ft in ipairs(fts) do
    ft_servers = vim.tbl_extend("force", ft_servers, r(ft))
  end

  local servers = { "bashls", "lua_ls", "html", "json_ls", "clangd", "emmet_language_server", "gopls" }

  for server_name, server_opts in pairs(ft_servers) do
    if server_opts.enabled ~= false then
      table.insert(servers, server_name)
    end
    if server_opts.keys then
      Utils.map.set(server_opts.keys, { lsp = { name = server_name } })
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
