function stash
set creds (keepassxc-cli show -a username -a password ~/Nextcloud/OVH/keepass.kdbx "Stash token")
set -U STASH_USER $creds[1]
set -U STASH_PWD $creds[2]
end
