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
# Connecté par `ssh -A` : garder l'agent transféré.
if not set -q SSH_CONNECTION; or not test -S "$SSH_AUTH_SOCK"
    set -e SSH_AUTH_SOCK
    set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
end

# Thème de bat, couleurs de fzf : conf.d/theme-auto.fish (clair/sombre selon le terminal).

if status is-interactive
    # Pas dans les shells non interactifs : nroff (groff) lance "$SHELL -c" dans le sandbox
    # seccomp de man-db, où mise activate panique (socket Unix refusé) à chaque `man`.
    mise activate fish | source
    # atuin prend Ctrl+R et ↑ : fzf.fish garde ses autres raccourcis, sans celui de l'historique.
    # Au plus tôt (juste après mise, qui fournit atuin) : pty_proxy relance fish dans le proxy,
    # tout ce qui précède s'exécute deux fois.
    functions -q fzf_configure_bindings; and fzf_configure_bindings --history=
    atuin init fish | source
    # gpg-agent sert d'agent SSH : une requête SSH ne transporte ni écran ni terminal, pinentry
    # prend ceux enregistrés par l'agent. Sans ceci, ce sont ceux de son démarrage (souvent avant
    # que la session graphique existe) et la demande de passphrase n'a nulle part où s'afficher.
    set -gx GPG_TTY (tty)
    gpg-connect-agent updatestartuptty /bye >/dev/null
    set -g fish_greeting ""
    zoxide init fish | source
    starship init fish | source
    if test -n "$(chezmoi status 2>/dev/null)"
        echo "dotfiles drift — run 'dotstatus'"
    end
end
