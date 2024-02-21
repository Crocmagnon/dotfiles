---@type ChadrcConfig
local M = {}

M.plugins = "custom.plugins"
M.mappings = require "custom.mappings"

M.ui = {
  theme = "onedark",
  statusline = {
    theme = "default",
    separator_style = "arrow",
  },
  tabufline = {
    lazyload = false,
    show_numbers = true,
  },
  hl_override = {
    CursorLine = {
      bg = "one_bg",
    },
  },
}

return M
