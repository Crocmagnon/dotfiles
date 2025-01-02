function light --description 'Set shell theme to light mode, including neovim'
	yes | fish_config theme save "Catppuccin Latte"
	set -Ux BAT_THEME "Catppuccin Latte"
	set -Ux FZF_DEFAULT_OPTS "\
--color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39 \
--color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78 \
--color=marker:#7287fd,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39 \
--color=selected-bg:#bcc0cc \
--multi"
	update_nvim_theme light
end
