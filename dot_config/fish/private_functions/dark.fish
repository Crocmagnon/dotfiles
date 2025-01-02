function dark --description 'Set shell theme to dark mode, including neovim'
	yes | fish_config theme save "Catppuccin Mocha"
	set -Ux BAT_THEME "Catppuccin Mocha"
	set -Ux FZF_DEFAULT_OPTS "\
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi"
	update_nvim_theme dark
end
