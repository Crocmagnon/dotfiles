function stash-automerge
    set creds (keepassxc cli show -a username -a password ~/Nextcloud/keepass.kdbx "Stash token")
    set -l STASH_USER $creds[1]
    set -l STASH_PWD $creds[2]
    ~/Projects/ovh/isupport/stash-automerge/dist/stash-automerge_linux_amd64 -username $STASH_USER -token $STASH_PWD
end
