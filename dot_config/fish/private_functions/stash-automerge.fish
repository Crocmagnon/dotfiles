function stash-automerge
    set -l user $STASH_USER
    set -l token $STASH_PWD
    if test -z "$user"; or test -z "$token"
        set creds (keepassxc cli show -a username -a password ~/Nextcloud/keepass.kdbx "Stash token")
        set user $creds[1]
        set token $creds[2]
    end
    ~/Projects/ovh/isupport/stash-automerge/dist/stash-automerge_linux_amd64 -username $user -token $token
end
