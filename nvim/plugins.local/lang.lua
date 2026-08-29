-- kotlindev — Kotlin language wiring for Neovim (langdev lang.lua)
-- SPDX-License-Identifier: Apache-2.0 OR MIT
--
-- The Kotlin Language Server (kotlin-language-server) is installed at BUILD time
-- by the toolchain stage and exposed on PATH via `/opt/langdev/toolchain/bin/kotlin-language-server`.
-- Mason stays disabled: no network on first launch, fully reproducible.
return {
  -- Treesitter grammar for Kotlin (compiled at build time).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "kotlin" })
    end,
  },

  -- Kotlin Language Server via nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = {
          mason = false,
          cmd = { "kotlin-language-server" },
          root_dir = function(fname)
            local util = require("lspconfig.util")
            return util.root_pattern(
              "settings.gradle.kts",
              "settings.gradle",
              "build.gradle.kts",
              "build.gradle",
              "pom.xml",
              ".git"
            )(fname)
          end,
          settings = {
            kotlin = {
              compiler = {
                jvm = {
                  target = "21",
                },
              },
            },
          },
        },
      },
    },
  },
}
