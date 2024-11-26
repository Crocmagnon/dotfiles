function dark --description 'Set shell theme to dark mode, including neovim'
yes | fish_config theme save "Catppuccin Mocha"
set -Ux BAT_THEME "Catppuccin Mocha"
update_nvim_theme dark
end
