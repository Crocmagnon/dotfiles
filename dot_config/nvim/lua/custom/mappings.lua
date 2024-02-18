local M = {}

M.dap = {
  plugin = true,
  n = {
    ["<leader>db"] = {
      "<cmd> DapToggleBreakpoint <CR>",
      "Add breakpoint at line"
    },
    ["<leader>dc"] = {
      "<cmd> DapContinue <CR>",
      "Debug - continue"
    },
    ["<leader>dsi"] = {
      "<cmd> DapStepInto <CR>",
      "Debug - step into"
    },
    ["<leader>dn"] = {
      "<cmd> DapStepOver <CR>",
      "Debug - step over (next)"
    },
    ["<leader>dso"] = {
      "<cmd> DapStepOut <CR>",
      "Debug - step out"
    },
    ["<leader>dt"] = {
      "<cmd> DapTerminate <CR>",
      "Debug - terminate"
    },
    ["<leader>dus"] = {
      function ()
        require("dapui").toggle();
        -- local widgets = require('dap.ui.widgets');
        -- local sidebar = widgets.sidebar(widgets.scopes);
        -- sidebar.open();
      end,
      "Toggle debugging interface"
    }
  }
}

M.dap_go = {
  plugin = true,
  n = {
    ["<leader>dgt"] = {
      function()
        require("dap-go").debug_test()
      end,
      "Debug go test"
    },
    ["<leader>dgl"] = {
      function()
        require("dap-go").debug_last_test()
      end,
      "Debug last go test"
    },
  }
}

M.dap_ui = {
  plugin = true,
  n = {
    ["È"] = { -- alt+k
      function()
        require("dapui").eval()
      end,
      "Debug - eval expression"
    }
  }
}

M.terminal = {
  t = {
    ["<Esc>"] = {"<C-\\><C-n>"}
  }
}

M.general = {
  i = {
    ["<C-a>"] = { "<ESC>^i", "Beginning of line" },
  }
}

return M
