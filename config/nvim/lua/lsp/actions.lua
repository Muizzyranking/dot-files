local M = {}

---@class LspPickerItem
---@field text string
---@field name string
---@field [any] any

M.ignored_servers = { "copilot" }

---@param name string
---@return boolean
function M.is_ignored(name)
  for _, ignored in ipairs(M.ignored_servers) do
    if name == ignored then
      return true
    end
  end
  return false
end

---@param opts table
---@return function
local function make_picker(opts)
  return function()
    return Snacks.picker(vim.tbl_deep_extend("force", {
      layout = { preset = "drop", preview = false },
      on_show = function()
        vim.cmd("stopinsert")
      end,
      win = {
        input = {
          keys = {
            ["<CR>"] = { "confirm", mode = { "n", "i" } },
          },
        },
      },
      actions = {
        confirm = function(picker, _)
          local selected = picker:selected({ fallback = true })
          picker:close()
          if opts.on_confirm then
            opts.on_confirm(selected)
          end
        end,
      },
    }, opts))
  end
end

function M.get_all_servers()
  local config_dir = vim.fn.stdpath("config")
  local lsp_dir = config_dir .. "/lsp"
  local servers = {}

  local entries = vim.uv.fs_scandir(lsp_dir)
  if entries then
    while true do
      local name, ftype = vim.uv.fs_scandir_next(entries)
      if not name then
        break
      end
      if ftype == "file" and name:match("%.lua$") then
        local server_name = (name:gsub("%.lua$", ""))
        if not M.is_ignored(server_name) then
          table.insert(servers, server_name)
        end
      end
    end
  end
  return servers
end

function M.get_running_servers()
  local items = {}
  for _, client in ipairs(Utils.lsp.get_clients()) do
    if not M.is_ignored(client.name) then
      table.insert(items, {
        text = client.name .. " (id: " .. client.id .. ")",
        name = client.name,
        id = client.id,
      })
    end
  end
  if #items == 0 then
    Utils.notify.warn("No LSP servers currently running")
    return {}
  end
  return items
end

function M.get_server_status()
  local all = M.get_all_servers()
  local running = {}

  for _, client in ipairs(Utils.lsp.get_clients()) do
    if not M.is_ignored(client.name) then
      running[client.name] = true
    end
  end

  local items = {}
  for _, name in ipairs(all) do
    table.insert(items, {
      text = running[name] and (name .. " [running]") or (name .. " [stopped]"),
      name = name,
      running = running[name] or false,
    })
  end
  return items
end

M.restart_picker = make_picker({
  title = "Restart LSP Servers",
  finder = M.get_running_servers,
  format = function(item)
    return { { "󰒋 ", "DiagnosticOk" }, { item.text } }
  end,
  on_confirm = function(selected)
    for _, item in ipairs(selected) do
      Utils.lsp.restart(item.name)
    end
  end,
})

M.stop_picker = make_picker({
  title = "Stop LSP Servers",
  finder = M.get_running_servers,
  format = function(item)
    return { { "󰒋 ", "DiagnosticError" }, { item.text } }
  end,
  on_confirm = function(selected)
    for _, item in ipairs(selected) do
      Utils.lsp.stop(item.name)
    end
  end,
})

M.start_picker = make_picker({
  title = "Start LSP Servers",
  finder = function()
    local all = M.get_all_servers()
    local running = {}
    for _, client in ipairs(vim.lsp.get_clients()) do
      running[client.name] = true
    end

    local items = {}
    for _, name in ipairs(all) do
      if not running[name] then
        table.insert(items, { text = name, name = name })
      end
    end
    if #items == 0 then
      Utils.notify.info("All enabled servers are already running")
      return {}
    end
    return items
  end,
  format = function(item)
    return { { "󰒌 ", "DiagnosticWarn" }, { item.text } }
  end,
  on_confirm = function(selected)
    for _, item in ipairs(selected) do
      Utils.lsp.start(item.name)
    end
  end,
})

function M.restart_all_attached()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    Utils.notify.warn("No LSP servers attached to current buffer")
    return
  end
  for _, client in ipairs(clients) do
    Utils.lsp.restart(client.name)
  end
end

function M.lsp_info()
  vim.cmd("checkhealth vim.lsp")
end

return M
