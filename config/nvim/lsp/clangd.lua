return {
  ft = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  capabilities = {
    offsetEncoding = { "utf-16" },
  },
  root_markers = {
    "compile_commands.json",
    "compile_flags.txt",
    "configure.ac", -- AutoTools
    "Makefile",
    "configure.ac",
    "configure.in",
    "config.h.in",
    "meson.build",
    "meson_options.txt",
    "build.ninja",
    ".git",
  },
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--fallback-style=llvm",
    "--offset-encoding=utf-16",
  },
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    clangdFileStatus = true,
  },
}
