function update_helix_theme --description 'Update helix theme' --argument-names theme
    set themesdir $HOME/.config/helix/themes
    mkdir -p $themesdir
    echo "inherits = \"$theme\"" >$themesdir/adaptive.toml
    pkill -USR1 hx || true
end
