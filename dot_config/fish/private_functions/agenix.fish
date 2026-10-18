function agenix --description 'agenix pinned by nixos-config, with the passphrase-less age identity'
    nix run --inputs-from ~/Projects/github.com/Crocmagnon/nixos-config agenix -- -i ~/.config/agenix/identity.txt $argv
end
