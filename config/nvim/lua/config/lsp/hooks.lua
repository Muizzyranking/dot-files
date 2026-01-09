-- lua/config/lsp/hooks.lua
local M = {}

---@class LspHook
---@field priority? number
---@field opts? table
---@field fn fun(opts: table): nil

---@type table<string, LspHook>
local hooks = {
  setup_keymaps = {
    opts = { enabled = true },
    fn = function()
      require("config.lsp.keymaps").setup()
    end,
  },
  enable_servers = {
    priority = 10,
    opts = { enabled = true, delay = 0 },
    fn = function(opts)
      vim.defer_fn(function()
        require("config.lsp.servers").setup()
      end, opts.delay or 0)
    end,
  },
  setup_codelens = {
    opts = { enabled = false, events = { "BufEnter", "CursorHold", "InsertLeave" } },
    fn = function(opts)
      Utils.lsp.on_method("textDocument/codeLens", function(_, buf)
        vim.lsp.codelens.refresh({ bufnr = buf })
        vim.api.nvim_create_autocmd(opts.events, {
          buffer = buf,
          callback = function()
            vim.lsp.codelens.refresh({ bufnr = buf })
          end,
        })
      end)
    end,
  },
  setup_document_color = {
    opts = { enabled = true },
    fn = function()
      Utils.lsp.on_method("textDocument/documentColor", function(_, buf)
        if vim.lsp.document_color ~= nil then
          vim.lsp.document_color.enable(true, buf)
        end
      end)
    end,
  },
  setup_document_highlight = {
    opts = { enabled = true, delay = 100 },
    fn = function(opts)
      if opts.delay then
        vim.opt.updatetime = opts.delay
      end
      Utils.lsp.on_method("textDocument/documentHighlight", function(_, buf)
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          buffer = buf,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
          buffer = buf,
          callback = vim.lsp.buf.clear_references,
        })
      end)
    end,
  },
  setup_folds = {
    opts = { enabled = true },
    fn = function()
      Utils.lsp.on_method("textDocument/foldingRange", function(_, buf)
        local win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_buf(win) == buf then
          vim.wo[win].foldmethod = "expr"
          vim.wo[win].foldexpr = "v:lua.vim.lsp.foldexpr()"
        end
      end)
    end,
  },
  setup_semantic_tokens = {
    opts = { enabled = true, disable_for = { "lua_ls" } },
    fn = function(opts)
      local disable_map = {}
      for _, server in ipairs(opts.disable_for or {}) do
        disable_map[server] = true
      end
      Utils.lsp.on_attach(function(client, _)
        if disable_map[client.name] then
          client.server_capabilities.semanticTokensProvider = nil
        end
      end)
    end,
  },
}

function M.run()
  local sorted_hooks = {}
  for name, hook in pairs(hooks) do
    table.insert(sorted_hooks, { name = name, hook = hook })
  end

  table.sort(sorted_hooks, function(a, b)
    local a_priority = a.hook.priority or 0
    local b_priority = b.hook.priority or 0
    return a_priority > b_priority
  end)

  for _, item in ipairs(sorted_hooks) do
    local opts = item.hook.opts or {}
    if opts.enabled ~= false then
      opts.enabled = nil
      local ok, err = pcall(item.hook.fn, opts)
      if not ok then
        Utils.notify.error(string.format("Hook '%s' failed: %s", item.name, err), { title = "LSP Hooks" })
      end
    end
  end
end

return M
