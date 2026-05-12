return {
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      jdtls = function(opts)
        opts.settings = {
          java = {
            format = {
              enabled = true,
              settings = {
                url = "/home/mihili/.dotfiles/.config/nvim/lua/config/java-formatter.xml",
              },
            },
            inlayHints = {
              parameterNames = {
                enabled = "all",
              },
            },
          },
        }
        return opts
      end,
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cpp = { "clang_format" },
        c = { "clang_format" },
      },
      formatters = {
        clang_format = {
          prepend_args = {
            "--style=file",
            "--fallback-style=none",
            "--assume-filename=" .. os.getenv("HOME") .. "/.clang-format",
          },
        },
      },
    },
  },
}
