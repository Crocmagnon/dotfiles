local plugins = {
  {
    "nvim-treesitter/nvim-treesitter", -- grammars
    opts = {
      ensure_installed = {
        "go",
        "lua",
        "python",
      },
      auto_install = true,
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    },
  },
  {
    "williamboman/mason.nvim", -- auto install tools
    opts = {
      ensure_installed = {
        "lua-language-server",
        "gopls",
        "gofumpt",
        "golangci-lint",
        "goimports",
      },
    },
  },
  {
    "mfussenegger/nvim-dap", -- generic debugger integration
    init = function()
      require("core.utils").load_mappings("dap")
    end,
  },
  {
    "leoluz/nvim-dap-go", -- specific go debugger integration
    ft = "go",
    dependencies = "mfussenegger/nvim-dap",
    config = function(_, opts)
      require("dap-go").setup(opts)
      require("core.utils").load_mappings("dap_go")
    end,
  },
  {
    "rcarriga/nvim-dap-ui", -- UI for the DAP debugger
    ft = "go",
    dependencies = "mfussenegger/nvim-dap",
    config = function()
      require("dapui").setup()
      require "custom.configs.nvim-dap-ui"
      require("core.utils").load_mappings("dap_ui")
    end,
  },
  {
    "neovim/nvim-lspconfig", -- load custom lsp config
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },
  {
    "nvimtools/none-ls.nvim", -- custom format on save
    ft = "go",
    opts = function()
      return require "custom.configs.null-ls"
    end,
  },
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    config = function(_, opts)
      require("gopher").setup(opts)
    end,
    build = function()
      vim.cmd [[silent! GoInstallDeps]]
    end,
  },
}
return plugins
