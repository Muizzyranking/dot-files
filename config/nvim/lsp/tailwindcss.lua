return {
  root_dir = function(buf, on_dir)
    local fname = Utils.get_filename(buf)
    local root_files = {
      "tailwind.config.js",
      "tailwind.config.cjs",
      "tailwind.config.mjs",
      "tailwind.config.ts",
      "postcss.config.js",
      "postcss.config.cjs",
      "postcss.config.mjs",
      "postcss.config.ts",
      -- django
      "theme/static_src/tailwind.config.js",
      "theme/static_src/tailwind.config.cjs",
      "theme/static_src/tailwind.config.mjs",
      "theme/static_src/tailwind.config.ts",
      "theme/static_src/postcss.config.js",
    }
    root_files = Utils.root.markers_with_field(root_files, { "package.json", "package-lock.json" }, "tailwind", fname)
    on_dir(vim.fs.dirname(vim.fs.find(root_files, { path = fname, upward = true })[1]))
  end,
  filetypes_exclude = { "markdown" },
  filetypes_include = {},
  settings = {
    tailwindCSS = {
      classAttributes = {
        "class",
        "className",
        "class:list",
        "classList",
        "ngClass",
      },
      includeLanguages = {
        elixir = "html-eex",
        eelixir = "html-eex",
        heex = "html-eex",
      },
    },
  },
}
