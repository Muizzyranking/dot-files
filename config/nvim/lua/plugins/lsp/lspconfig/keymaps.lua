local M = {}
M._keys = nil

function M.get()
  if M._keys then
    return M._keys
  end
  M._keys = {
    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "Goto Definition",
      has = "definition",
    },
    -- vsplit jump
    {
      "gD",
      function()
        Snacks.picker.lsp_definitions({ confirm = "edit_vsplit" })
      end,
      desc = "Goto Definition (Vsplit)",
      has = "definition",
    },
    {
      "gr",
      function()
        Snacks.picker.lsp_references()
      end,
      nowait = true,
      desc = "References",
    },
    {
      "gT",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "Goto Implementation",
    },
    {
      "<leader>cs",
      function()
        Snacks.picker.lsp_symbols({
          layout = { preset = "code", preview = "main" },
          on_show = function()
            vim.cmd("stopinsert")
          end,
        })
      end,
      desc = "Lsp Symbols",
      has = "documentSymbol",
    },
    {
      "<leader>sS",
      function()
        Snacks.picker.lsp_workspace_symbols({ filter = Utils.lsp.kind_filter })
      end,
      desc = "LSP Workspace Symbols",
      has = "workspace/symbols",
    },

    -- { "gd", vim.lsp.buf.definition, desc = "Goto Definition", has = "definition" },
    -- { "gr", vim.lsp.buf.references, desc = "References" },
    -- { "gI", vim.lsp.buf.implementation, desc = "Goto Implementation" },
    -- { "gT", vim.lsp.buf.type_definition, desc = "Goto Type Definition" },
    -- { "g;", vim.lsp.buf.declaration, desc = "Goto Declaration", has = "declaration" },
    {
      "K",
      function()
        return vim.lsp.buf.hover()
      end,
      desc = "Hover",
    },
    {
      "K",
      function()
        vim.lsp.buf.hover()
      end,
      desc = "Hover",
      has = "hover",
    },
    {
      "]d",
      Utils.lsp.diagnostic_goto(true),
      desc = "Next Diagnostic",
    },
    {
      "[d",
      Utils.lsp.diagnostic_goto(false),
      desc = "Prev Diagnostic",
    },
    {
      "]e",
      Utils.lsp.diagnostic_goto(true, "ERROR"),
      desc = "Next Error",
    },
    {
      "[e",
      Utils.lsp.diagnostic_goto(false, "ERROR"),
      desc = "Prev Error",
    },
    {
      "]w",
      Utils.lsp.diagnostic_goto(true, "WARN"),
      desc = "Next Warning",
    },
    {
      "[w",
      Utils.lsp.diagnostic_goto(false, "WARN"),
      desc = "Prev Warning",
    },
    {
      "gy",
      Utils.lsp.copy_diagnostics,
      desc = "Yank diagnostic message on current line",
      icon = { icon = "󰆏 ", color = "blue" },
      mode = { "n", "x" },
    },
    {
      "<leader>cf",
      function()
        Utils.format({ force = true })
      end,
      desc = "Format buffer",
      icon = { icon = " ", color = "green" },
      mode = { "n", "v" },
    },
    {
      "<leader>cl",
      "<cmd>LspInfo<cr>",
      desc = "Lsp Info",
      icon = { icon = " ", color = "blue" },
    },
    {
      "<leader>ca",
      vim.lsp.buf.code_action,
      desc = "Code Action",
      icon = { icon = " ", color = "orange" },
      has = "codeAction",
      mode = { "n", "v" },
    },
    {
      "<leader>cr",
      Utils.lsp.rename,
      desc = "Rename",
      icon = { icon = "󰑕 ", color = "orange" },
      expr = true,
      has = "rename",
      silent = false,
    },
    Utils.map.toggle_map({
      "<leader>ui",
      get_state = function(buf)
        return vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
      end,
      change_state = function(state, buf)
        vim.lsp.inlay_hint.enable(not state, { bufnr = buf })
      end,
      name = "Inlay hint",
      has = "inlayHint",
      set_key = false,
    }),
  }

  return M._keys
end

local all_keys = {}
function M.on_attach(_, buffer, opts)
  pcall(vim.keymap.del, "n", "gra")
  pcall(vim.keymap.del, "n", "grn")
  pcall(vim.keymap.del, "n", "grr")
  pcall(vim.keymap.del, "n", "gri")
  local clients = Utils.lsp.get_clients({ bufnr = buffer })
  local keys = vim.tbl_extend("force", {}, M.get())
  for _, client in ipairs(clients) do
    local maps = opts.servers[client.name] and opts.servers[client.name].keys or {}
    vim.list_extend(keys, maps)
  end
  for _, key in ipairs(keys) do
    local has = not key.has or Utils.lsp.has(buffer, key.has)
    if has then
      key.has = nil
      key.buffer = buffer
      key.silent = key.silent ~= false
      all_keys[#all_keys + 1] = key
    end
  end
  Utils.map.set_keymaps(all_keys)
end

return M
