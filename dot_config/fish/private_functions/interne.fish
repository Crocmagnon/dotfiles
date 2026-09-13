function interne
    set creds (keepassxc cli show -a username -a password ~/Nextcloud/keepass.kdbx Interne)
    set -g INTERNE_USER $creds[1]
    set -g INTERNE_PWD $creds[2]
end
