function light --description 'Set shell theme to light mode, including neovim'
yes | fish_config theme save "Catppuccin Latte"
update_nvim_theme light
end
