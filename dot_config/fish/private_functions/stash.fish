function stash
    set creds (keepassxc cli show -a username -a password ~/Nextcloud/keepass.kdbx "Stash token")
    set -g STASH_USER $creds[1]
    set -g STASH_PWD $creds[2]
end
