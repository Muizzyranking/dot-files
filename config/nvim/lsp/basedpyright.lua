return {
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
        autoImportCompletions = true,
      },
      disableOrganizeImports = true,
    },
  },
  on_new_config = function(config, root_dir)
    local venv = Utils.python.detect_and_activate_venv(root_dir)
    if venv then
      config.settings = config.settings or {}
      config.settings.python = config.settings.python or {}
      config.settings.python.pythonPath = venv.python_path
    end
  end,
  on_attach = function(client, bufnr)
    local current_python = client.config.settings
      and client.config.settings.python
      and client.config.settings.python.pythonPath

    local root = Utils.root(bufnr)
    local venv = Utils.python.detect_and_activate_venv(root)
    local new_python = venv and venv.python_path

    if new_python and new_python ~= current_python then
      local client_settings
      if client.settings then
        client.settings = vim.tbl_deep_extend("force", client.settings, { python = { pythonPath = new_python } })
        client_settings = client.settings
      elseif client.config.settings then
        client.config.settings =
          vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = new_python } })
        client_settings = client.config.settings
      end

      -- Force configuration update
      client.notify("workspace/didChangeConfiguration", { settings = client_settings })
    end

    Utils.autocmd.create("BufWritePre", {
      pattern = { "*pyrightconfig.json" },
      callback = function()
        Utils.lsp.restart("basedpyright")
        vim.cmd("stopinsert")
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
      end,
      buffer = bufnr,
    })
  end,
  keys = {
    {
      "<leader>ci",
      function()
        vim.lsp.buf.code_action({
          filter = function(a)
            return a.title:find("import") ~= nil and a.kind == "quickfix"
          end,
          apply = true,
        })
      end,
      desc = "Auto import word under cursor",
      icon = { icon = "󰋺 ", color = "blue" },
    },
  },
}
