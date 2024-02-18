---@type ChadrcConfig
local M = {}

M.plugins = "custom.plugins"
M.mappings = require "custom.mappings"

M.ui = {
  theme = "tomorrow_night",
  statusline = {
    theme = "default",
    separator_style = "arrow",
  },
  tabufline = {
    lazyload = false,
    show_numbers = true,
  },
}

return M
