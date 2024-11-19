function update_nvim_theme --description 'Update neovim theme with light/dark mode' --argument theme
for addr in $NVIM_TMP_DIR/**/*
nvim --server $addr --remote-send ":set background=$theme <cr>"
end
end
