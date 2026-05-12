return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      -- CodeLLDB adapter (LazyVim does not define it by default)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }

      dap.configurations.rust = {
        {
          name = "Debug Rust (custom args)",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.getcwd() .. "/target/debug/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,

          -- 🔑 THIS IS THE IMPORTANT PART
          args = function()
            local args = vim.fn.input("Args: ")
            return vim.split(args, " ")
          end,
        },
      }
    end,
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      local dap = require("dap")
      local mason = vim.fn.stdpath("data") .. "/mason"
      local codelldb = mason .. "/packages/codelldb/extension/adapter/codelldb"

      -- Setup CodeLLDB adapter
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = codelldb,
          args = { "--port", "${port}" },
        },
      }

      -- Helper function to build the project
      local function build_project()
        local build_dir = vim.fn.getcwd() .. "/build"

        -- Create build directory if it doesn't exist
        vim.fn.mkdir(build_dir, "p")

        print("Building Qt project...")

        -- Run cmake and make
        local cmake_cmd = string.format("cd %s && cmake -DCMAKE_BUILD_TYPE=Debug .. && make", build_dir)

        local result = vim.fn.system(cmake_cmd)

        if vim.v.shell_error ~= 0 then
          print("Build failed! Check :messages for details")
          print(result)
          return false
        end

        print("Build successful!")
        return true
      end

      -- Helper function to find the executable in build directory
      local function find_executable()
        local build_dir = vim.fn.getcwd() .. "/build"
        local executables = vim.fn.globpath(build_dir, "*", false, true)

        -- Filter for executable files (not CMake files or directories)
        for _, file in ipairs(executables) do
          if vim.fn.executable(file) == 1 and not file:match("CMake") then
            return file
          end
        end

        return nil
      end

      -- C++ Debug Configurations
      dap.configurations.cpp = {
        {
          name = "Build & Debug Qt App",
          type = "codelldb",
          request = "launch",
          program = function()
            -- Build first
            if not build_project() then
              return nil
            end

            -- Find the executable
            local exe = find_executable()
            if exe then
              print("Found executable: " .. exe)
              return exe
            else
              -- If auto-find fails, ask user
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
            end
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
          env = {
            QT_QPA_PLATFORM = "xcb", -- Change to "wayland" if needed
          },
        },
        {
          name = "Debug Qt App (Skip Build)",
          type = "codelldb",
          request = "launch",
          program = function()
            local exe = find_executable()
            if exe then
              return exe
            else
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
            end
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
          env = {
            QT_QPA_PLATFORM = "xcb",
          },
        },
      }

      -- Copy config for C files
      dap.configurations.c = dap.configurations.cpp
    end,
  },

  -- Optional but highly recommended: DAP UI for visual debugging
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap, dapui = require("dap"), require("dapui")

      dapui.setup()

      -- Auto-open/close DAP UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
}
