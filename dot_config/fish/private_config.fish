set -gx SHELL (which fish)

fish_add_path -g $HOME/.local/bin $HOME/go/bin $HOME/.local/git-toolbelt

set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

set -gx LANG en_US.UTF-8

set -gx ANSIBLE_NOCOWS 1

set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

set -gx PIP_REQUIRE_VIRTUALENV true
set -gx MISE_PYTHON_VENV_AUTO_CREATE true

set -gx EDITOR hx

# fix man output with bat (remove color codes)
set -gx GROFF_NO_SGR 1

gpgconf --launch gpg-agent
set -e SSH_AUTH_SOCK
set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)

set -gx BAT_THEME "Catppuccin Latte"

set -gx FZF_DEFAULT_OPTS "\
--color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39 \
--color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78 \
--color=marker:#7287fd,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39 \
--color=selected-bg:#bcc0cc \
--multi"

mise activate fish | source

if status is-interactive
    set -g fish_greeting ""
    zoxide init fish | source
    starship init fish | source
end
