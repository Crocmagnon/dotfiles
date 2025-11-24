function update_helix_theme --description 'Update helix theme' --argument-names theme
    echo "inherits = \"$theme\"" > $HOME/.config/helix/themes/adaptive.toml 
    pkill -USR1 hx || true
end
