function interne
  set creds (keepassxc-cli show -a username -a password ~/Nextcloud-OVH/keepass.kdbx Interne)
  set -U INTERNE_USER $creds[1]
  set -U INTERNE_PWD $creds[2]
end
