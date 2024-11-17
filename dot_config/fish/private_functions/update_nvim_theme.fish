function update_nvim_theme --description 'Update neovim theme with light/dark mode' --argument theme
for addr in /var/folders/7r/l55lwv013hl_g8gc971k7kgw0000gn/T/nvim.gaugendre/**/*
nvim --server $addr --remote-send ":set background=$theme <cr>"
end
end
