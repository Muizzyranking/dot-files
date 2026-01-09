local M = {}
function M.setup()
  local python = require("config.lsp.servers.python")
  local typescript = require("config.lsp.servers.typescript")

  local list = vim.tbl_extend("force", {}, python, typescript)

  local servers = { "lua_ls", "html", "json_ls", "clangd", "emmet_language_server", "gopls" }

  for server_name, server_opts in pairs(list) do
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
