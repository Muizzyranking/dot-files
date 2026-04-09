return {
  {
    "gd",
    function()
      Utils.lsp.goto_definition()
    end,
    desc = "Goto Definition",
    has = "definition",
  },
  {
    "gD",
    function()
      Utils.lsp.goto_definition({ direction = "vsplit" })
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
        layout = { preset = "vscode", preview = "main" },
        on_show = function()
          vim.cmd("stopinsert")
        end,
      })
    end,
    desc = "Lsp Symbols",
    has = "documentSymbol",
  },
  {
    "<c-k>",
    function()
      return vim.lsp.buf.signature_help()
    end,
    desc = "Signature Help",
    has = "signatureHelp",
    mode = "i",
  },
  {
    "K",
    function()
      vim.lsp.buf.hover()
    end,
    desc = "Hover",
    has = "hover",
  },
  { "]d", Utils.lsp.goto_diagnostics(true), desc = "Next Diagnostic" },
  { "[d", Utils.lsp.goto_diagnostics(false), desc = "Prev Diagnostic" },
  { "]e", Utils.lsp.goto_diagnostics(true, "ERROR"), desc = "Next Error" },
  { "[e", Utils.lsp.goto_diagnostics(false, "ERROR"), desc = "Prev Error" },
  { "]w", Utils.lsp.goto_diagnostics(true, "WARN"), desc = "Next Warning" },
  { "[w", Utils.lsp.goto_diagnostics(false, "WARN"), desc = "Prev Warning" },
  { "]i", Utils.lsp.goto_diagnostics(true, "HINT"), desc = "Next Hint" },
  {
    "gy",
    Utils.lsp.copy_diagnostics,
    desc = "Yank diagnostic message on current line",
    icon = { icon = "󰆏 ", color = "blue" },
    mode = { "n", "x" },
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
    function()
      local inc_rename = require("inc_rename")
      return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
    end,
    desc = "Rename",
    icon = { icon = "󰑕 ", color = "orange" },
    expr = true,
    has = "rename",
    silent = false,
  },
  {
    "<leader>ui",
    get = function(buf)
      return vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
    end,
    set = function(state, buf)
      vim.lsp.inlay_hint.enable(not state, { bufnr = buf })
    end,
    name = "Inlay hint",
    has = "inlayHint",
  },
  {
    "<leader>lr",
    function()
      require("lsp.actions").restart_picker()
    end,
    desc = "Restart LSP server(s)",
    icon = { icon = "󰜉 ", color = "orange" },
  },
  {
    "<leader>lR",
    function()
      require("lsp.actions").restart_all_attached()
    end,
    desc = "Restart all attached LSP servers",
    icon = { icon = "󰜉 ", color = "orange" },
  },
  {
    "<leader>li",
    function()
      require("lsp.actions").lsp_info()
    end,
    desc = "LSP info",
    icon = { icon = " ", color = "blue" },
  },
  {
    "<leader>ls",
    function()
      require("lsp.actions").stop_picker()
    end,
    desc = "Stop LSP server(s)",
    icon = { icon = "󰒋 ", color = "red" },
  },
  {
    "<leader>ls",
    function()
      require("lsp.actions").start_picker()
    end,
    desc = "Start LSP server(s)",
    icon = { icon = "󰒌 ", color = "green" },
  },
}
