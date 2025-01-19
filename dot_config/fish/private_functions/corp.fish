function corp
  set creds (keepassxc-cli show -a username -a password ~/Nextcloud/OVH/keepass.kdbx corp)
  set -g CORP_USER $creds[1]
  set -g CORP_PWD $creds[2]
end
