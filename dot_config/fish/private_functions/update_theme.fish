function update_theme --on-variable macOS_Theme
    if [ "$macOS_Theme" = "dark" ]
        yes | fish_config theme save "Catppuccin Mocha"
    else if [ "$macOS_Theme" = "light" ]
        yes | fish_config theme save "Catppuccin Latte"
    end
end
