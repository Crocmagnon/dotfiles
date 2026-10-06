function decman-update --description 'Pull arch-config then run decman, like chezmoi update (e.g. --dry-run)'
    git -C ~/Projects/codeberg.org/Crocmagnon/arch-config pull --ff-only; or return
    sudo decman $argv
end
