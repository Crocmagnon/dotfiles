# Bascule Catppuccin latte/mocha selon la couleur de fond du terminal (repris de nixos-config,
# modules/home/shared/theme-auto.nix). fish >= 4.3 interroge le terminal (OSC 11), pose
# fish_terminal_color_theme et applique la bonne section de themes/catppuccin.theme. bat et kitty
# détectent le fond eux-mêmes ; starship, eza, helix et fzf suivent grâce au hook ci-dessous.
# Avec un fish plus ancien, rien de tout ça : thème et couleurs par défaut.
status is-interactive; or return
string match -qr '^(4\.([3-9]|\d\d)|[5-9])' -- $version; or return

fish_config theme choose catppuccin
# Le thème catppuccin ne définit pas fish_color_valid_path, contrairement au thème par défaut.
set -g fish_color_valid_path --underline

function __theme_auto --on-variable fish_terminal_color_theme
    # Tant que le terminal n'a pas répondu, la variable est vide : ne rien faire, sinon helix
    # clignoterait vers le clair à chaque nouveau terminal.
    test -z "$fish_terminal_color_theme"; and return 0

    set -l fzf_base --multi
    if test "$fish_terminal_color_theme" = dark
        set flavor mocha
        set -gx STARSHIP_CONFIG ~/.config/starship-mocha.toml
        set -gx EZA_CONFIG_DIR ~/.local/share/eza-mocha
        set -gx FZF_DEFAULT_OPTS $fzf_base \
            --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
            --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
            --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
            --color=selected-bg:#45475a
    else
        set flavor latte
        set -e STARSHIP_CONFIG
        set -e EZA_CONFIG_DIR
        set -gx FZF_DEFAULT_OPTS $fzf_base \
            --color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39 \
            --color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78 \
            --color=marker:#7287fd,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39 \
            --color=selected-bg:#bcc0cc
    end

    # helix garde un nom de thème constant (catppuccin) : on change ce qu'il hérite, et SIGUSR1
    # lui fait relire sa config. N'écrire et ne signaler que si ça change. -x : sinon pkill
    # matche par sous-chaîne et SIGUSR1 tuerait un processus qui ne le gère pas.
    set -l theme_file ~/.config/helix/themes/catppuccin.toml
    set -l want "inherits = \"catppuccin-$flavor\""
    if test "$(cat $theme_file 2>/dev/null)" != "$want"
        echo $want > $theme_file
        pkill -USR1 -x hx
    end
    return 0
end
__theme_auto
